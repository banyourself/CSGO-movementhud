static Handle HudSync;

MHudEnumPreference KeysMode;
MHudXYPreference KeysPosition;
MHudRGBPreference KeysNormalColor;
MHudRGBPreference KeysOverlapColor;
MHudBoolPreference KeysMouseDirection;
MHudBoolPreference KeysColorBySpeed;

static const char Modes[KeysMode_COUNT][] =
{
    "Disabled",
    "Blanks as underscores",
    "Blanks invisible"
};

void OnPluginStart_Element_Keys()
{
    HudSync = CreateHudSynchronizer();

    KeysMode = new MHudEnumPreference("keys_mode", "Keys - Mode", Modes, sizeof(Modes) - 1, KeysMode_None);
    KeysPosition = new MHudXYPreference("keys_position", "Keys - Position", -1, 800);
    KeysNormalColor = new MHudRGBPreference("keys_color_normal", "Keys - Normal Color", 255, 255, 255);
    KeysOverlapColor = new MHudRGBPreference("keys_color_overlap", "Keys - Overlap Color", 255, 0, 0);
    KeysMouseDirection = new MHudBoolPreference("keys_mouse_direction", "Keys - Mouse Direction", false);
    KeysColorBySpeed = new MHudBoolPreference("keys_color_from_speed", "Keys - Color by Speed", false);
}

void OnPlayerRunCmdPost_Element_Keys(int client, int target)
{
    int mode = KeysMode.GetInt(client);
    if (mode == KeysMode_None)
    {
        return;
    }

    int buttons = gI_Buttons[target];
    bool showJump = JumpedRecently(target);
    bool colorBySpeed = KeysColorBySpeed.GetBool(client);

    float xy[2];
    KeysPosition.GetXY(client, xy);

    int rgb[3];
    if (!colorBySpeed)
    {
        MHudRGBPreference colorPreference = DidButtonsOverlap(buttons)
            ? KeysOverlapColor
            : KeysNormalColor;

        colorPreference.GetRGB(client, rgb);
    }
    else
    {
        float speed = gF_CurrentSpeed[target];
        GetColorBySpeed(speed, rgb);
    }

    // char[4] fits the em-dash glyph (3 UTF-8 bytes + nul); the old
    // ternary assignment into char[2] only compiled on newer spcomp.
    char blank[4];
    if (mode == KeysMode_NoBlanks)
    {
        strcopy(blank, sizeof(blank), "  ");
    }
    else
    {
        strcopy(blank, sizeof(blank), "—");
    }

    Call_OnDrawKeys(client, xy, rgb);

    // Built first, then compared: keys change on a keypress, not on a tick.
    char buffer[160];
    bool showMouseDirection = KeysMouseDirection.GetBool(client);
    if (!showMouseDirection)
    {
        FormatEx(buffer, sizeof(buffer), "%s  %s  %s\n%s  %s  %s",
            (buttons & IN_DUCK)       ? "C" : blank,
            (buttons & IN_FORWARD)    ? "W" : blank,
            (showJump)                ? "J" : blank,
            (buttons & IN_MOVELEFT)   ? "A" : blank,
            (buttons & IN_BACK)       ? "S" : blank,
            (buttons & IN_MOVERIGHT)  ? "D" : blank
        );
    }
    else
    {
        int mouseX = gI_MouseX[target];

        FormatEx(buffer, sizeof(buffer), "%s  %s  %s\n%s %s  %s  %s %s",
            (buttons & IN_DUCK)       ? "C" : blank,
            (buttons & IN_FORWARD)    ? "W" : blank,
            (showJump)                ? "J" : blank,
            (mouseX < 0)              ? "←" : blank,
            (buttons & IN_MOVELEFT)   ? "A" : blank,
            (buttons & IN_BACK)       ? "S" : blank,
            (buttons & IN_MOVERIGHT)  ? "D" : blank,
            (mouseX > 0)              ? "→" : blank
        );
    }

    if (!HudNeedsSend(client, MHUD_SLOT_KEYS, buffer, xy, rgb))
    {
        return;
    }

    SetHudTextParams(xy[0], xy[1], 0.5, rgb[0], rgb[1], rgb[2], 255, _, _, 0.0, 0.0);
    ShowSyncHudText(client, HudSync, "%s", buffer);
}

static bool DidButtonsOverlap(int buttons)
{
    return buttons & (IN_FORWARD | IN_BACK) == (IN_FORWARD | IN_BACK)
        || buttons & (IN_MOVELEFT | IN_MOVERIGHT) == (IN_MOVELEFT | IN_MOVERIGHT);
}
