// Every element re-sent its HudMsg on every single usercmd, so a player with
// keys, speed and indicators on cost three unreliable usermessages per tick
// before any other plugin drew anything. On a busy server the entity snapshot
// already eats most of the datagram, the unreliable buffer overflows, and a
// dropped HudMsg is an element blinking out - which is why this only shows up
// with a lot of players, and gets worse the moment speclist starts drawing to
// someone being spectated.
//
// Re-sending an identical message buys nothing. The 0.5s hold only has to be
// refreshed before it expires, so unchanged content goes out at MHUD_HUD_REFRESH
// instead of every tick. 0.2 leaves two whole dropped sends of margin under the
// hold, so a drop still self-heals faster than the text can expire.
#define MHUD_HUD_REFRESH 0.2

#define MHUD_SLOT_KEYS       0
#define MHUD_SLOT_SPEED      1
#define MHUD_SLOT_INDICATORS 2
#define MHUD_HUD_SLOTS       3

static char g_sHudLast[MAXPLAYERS + 1][MHUD_HUD_SLOTS][160];
static float g_fHudLastXY[MAXPLAYERS + 1][MHUD_HUD_SLOTS][2];
static int g_iHudLastRGB[MAXPLAYERS + 1][MHUD_HUD_SLOTS][3];
static float g_fHudLastAt[MAXPLAYERS + 1][MHUD_HUD_SLOTS];

// Position and color are part of the message, so either changing has to resend
// even when the text is byte-identical.
bool HudNeedsSend(int client, int slot, const char[] text, const float xy[2], const int rgb[3])
{
    float now = GetEngineTime();

    bool same = (now - g_fHudLastAt[client][slot]) < MHUD_HUD_REFRESH
        && xy[0] == g_fHudLastXY[client][slot][0]
        && xy[1] == g_fHudLastXY[client][slot][1]
        && rgb[0] == g_iHudLastRGB[client][slot][0]
        && rgb[1] == g_iHudLastRGB[client][slot][1]
        && rgb[2] == g_iHudLastRGB[client][slot][2]
        && StrEqual(g_sHudLast[client][slot], text);

    if (same)
    {
        return false;
    }

    strcopy(g_sHudLast[client][slot], sizeof(g_sHudLast[][]), text);
    g_fHudLastXY[client][slot][0] = xy[0];
    g_fHudLastXY[client][slot][1] = xy[1];
    g_iHudLastRGB[client][slot][0] = rgb[0];
    g_iHudLastRGB[client][slot][1] = rgb[1];
    g_iHudLastRGB[client][slot][2] = rgb[2];
    g_fHudLastAt[client][slot] = now;
    return true;
}

void GetColorBySpeed(float speed, int rgb[3])
{
    int x = RoundFloat(speed / 50.0) * 32;
    if (x >= 256)
    {
        rgb = { 0, 255, 0 };
        return;
    }

    rgb[0] = (255 - x);
    rgb[1] = x;
    rgb[2] = 0;
}

int GetSpectedOrSelf(int client)
{
    int team = GetClientTeam(client);
    if (team != 1) // not spectating, replace with define/enum please
    {
        return client;
    }

    // TODO: Enum for this?
    int mode = GetEntProp(client, Prop_Send, "m_iObserverMode");
    if (mode != 4 && mode != 5) // Not first or third person
    {
        return client;
    }

    int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
    if (target == -1) // not spectating anyone
    {
        return client;
    }

    return target;
}

void StripColorBytes(char[] buffer, int maxlength)
{
    int pos = 0;
    char[] output = new char[maxlength];

    int len = strlen(buffer);

    for (int i = 0; i < len; i++)
    {
        bool isColor = buffer[i] >= '\x01' && buffer[i] <= '\x10';
        if (!isColor)
        {
            output[pos++] = buffer[i];
        }
    }

    strcopy(buffer, maxlength, output);
}
