#include <sdkhooks>
#include <sdktools>
#include <topmenus>
#include <sourcemod>
#include <clientprefs>

#pragma tabsize 4

#include <json>
#include <base64>

#pragma semicolon 1
#pragma newdecls required

bool gB_IsReady;

#include <movementhud>

#include "movementhud/utils.sp"
#include "movementhud/movement.sp"
#include "movementhud/elements/keys.sp"
#include "movementhud/elements/speed.sp"
#include "movementhud/elements/indicators.sp"

#include "movementhud/preferences.sp"
#include "movementhud/preferences_code.sp"
#include "movementhud/preferences_menu.sp"
#include "movementhud/preferences_defaults.sp"
#include "movementhud/preferences_chatinput.sp"

#include "movementhud/commands.sp"
#include "movementhud/api/natives.sp"
#include "movementhud/api/forwards.sp"

public Plugin myinfo =
{
    name = "MHUD",
    author = "Sikari + Kevin",
    description = "Provides customizable movement displays",
    version = MHUD_VERSION,
    url = MHUD_SOURCE_URL
};

// 3.0.7 accepts a UTF-8 BOM in the defaults config.
// 3.0.8 stops re-sending unchanged HudMsgs every tick (HudNeedsSend in
// movementhud/utils.sp) and drops the dead sourcelen/is_array args behind the
// warning 217s. Removing the args beats a #pragma unused, which desyncs spcomp's
// indent tracker. MHUD_VERSION is in include/movementhud.inc, so touch this file
// too or a timestamp-driven build skips it.
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("MovementHUD");

    OnAskPluginLoad2_Natives();
    OnAskPluginLoad2_Forwards();

    return APLRes_Success;
}

public void OnPluginStart()
{
    OnPluginStart_Commands();
    OnPluginStart_Movement();
    OnPluginStart_Preferences();
    OnPluginStart_PreferencesDefaults();

    OnPluginStart_Element_Speed();
    OnPluginStart_Element_Keys();
    OnPluginStart_Element_Indicators();

    OnPluginStart_PreferencesCode();

    Call_OnReady();
    gB_IsReady = true;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i))
        {
            OnClientPutInServer(i);
        }
    }
}

public void OnClientPutInServer(int client)
{
    OnClientPutInServer_Movement(client);
    OnClientPutInServer_Preferences(client);
    OnClientPutInServer_PreferencesMenu(client);
    OnClientPutInServer_PreferencesChatInput(client);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    OnPlayerRunCmdPost_Movement(client, buttons, mouse);

    if (!IsFakeClient(client))
    {
        int target = GetSpectedOrSelf(client);

        OnPlayerRunCmdPost_Element_Keys(client, target);
        OnPlayerRunCmdPost_Element_Speed(client, target);
        OnPlayerRunCmdPost_Element_Indicators(client, target);
    }
}
