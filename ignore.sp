#include <sourcemod>
#include <sdktools_voice>
#include <chat-processor>

public Plugin:myinfo =
{
	name = "Ignore",
	author = "Arcala the Gyiyg",
	description = "Plugin that allows players to ignore the chat, voice, or both of other players.",
	version = "1.0.0",
	url = "N/A"
}

// Shoutout to Chdata for the original ignore command this is based on.

/* Description
*
* Creates a 2 bool arrays for every possible client on the server
* First arg is client who called command, second arg is other clients on server
* Third arg is voice
*
*/
bool a_bIgnoreStatusVoice[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool a_bIgnoreStatusChat[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool g_bisEnabled;

public void OnPluginStart()
{
    RegConsoleCmd("sm_ignore", ToggleIgnore, "Usage: !ignore <name> | Toggles ignoring user's voice chat, use @all to target all players.");
}

public OnAllPluginsLoaded()                     //  Check for necessary plugin dependencies and shut down this plugin if not found.
{
    if (!LibraryExists("chat-processor"))
    {
        SetFailState("[Ignore] Chat Processor is not loaded, please load chat-processor.smx");
    }
}

public OnLibraryAdded(const String:name[])      //  Enable the plugin if the necessary library is added
{
    if (StrEqual(name, "chat-processor"))
    {
        g_bisEnabled = true;
    }
}

public OnLibraryRemoved(const String:name[])    //  If a necessary plugin is removed, also shut this one down.
{
    if (StrEqual(name, "chat-processor"))
    {
        g_bisEnabled = false;
    }
}

public void OnClientDisconnect(int client)
{
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        a_bIgnoreStatusVoice[client][i] = false;
        a_bIgnoreStatusChat[client][i] = false;
    }
}

void ToggleIgnoreArray(int client, int target, int ignoreType)
{
    char TargName[128];
    GetClientName(target, TargName, MAXLENGTH_NAME);
    if (client == target)
    {
        return;
    }
    if (ignoreType == 1)
    {
        a_bIgnoreStatusVoice[client][target] = !a_bIgnoreStatusVoice[client][target];
        if (a_bIgnoreStatusVoice[client][target])
        {
            PrintToChat(client, "[Ignore] Successfully ignored %s's voice chat.", TargName);
            SetListenOverride(client, target, Listen_No);
        }
        else
        {
            PrintToChat(client, "[Ignore] Successfully unignored %s's voice chat.", TargName);
            SetListenOverride(client, target, Listen_Default);
        }
    }
    else
    {
        PrintToChat(client, "[Ignore] Usage: !ignore <name> | Toggles ignoring user's voice chat, use @all to target all players.");
    }
}

// public Action:CP_OnChatMessage(int &author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool &processcolors, bool &removecolors)
// {
//     if (g_bisEnabled)
//     {
//         if ((author < 0) || (author > MaxClients))
//         {
//             LogError("[Ignore] Warning: author is out of bounds: %d", author);
//             return Plugin_Continue;
//         }

//         for(int i = 0; i < GetArraySize(recipients); i++)
//         {
//             int client = recipients.Get(i);
//             if(a_bIgnoreStatusChat[client][author])
//             {
//                 recipients.Erase(client);
//             }
//         }
//         return Plugin_Continue;
//     }
//     return Plugin_Stop;
// }

public Action:ToggleIgnore(int client, int args)
{
    
    if (g_bisEnabled)
    {
        char tempArg[MAXLENGTH_NAME];
        int tempTargArray[MAXPLAYERS + 1];
        int tempProcessStringBuffer;
        char tempTargName[MAXLENGTH_NAME];
        bool tempStringIsML;
        bool b_TargetAll = false;
        if (args == 0 || args > 1)
        {
            ReplyToCommand(client, "[Ignore] Usage: !ignore <name> | Toggles ignoring user's voice chat, use @all to target all players.");
            return Plugin_Handled;
        }
        GetCmdArgString(tempArg, sizeof(tempArg));
        StripQuotes(tempArg);
        if(strcmp(tempArg, "@all", false) == 0)
        {
            b_TargetAll = true;
        }
        tempProcessStringBuffer = ProcessTargetString(tempArg, client, tempTargArray, MAXPLAYERS + 1, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_NO_IMMUNITY, tempTargName, 128, tempStringIsML);
        if (tempProcessStringBuffer <= 0)
        {
            ReplyToTargetError(client, tempProcessStringBuffer);
            return Plugin_Handled;
        }
        if (b_TargetAll)
        {
            for (int i = 1; i < (MAXPLAYERS + 1); i++)
            {
                ToggleIgnoreArray(client, i, 1);
            }
            return Plugin_Handled;
        }
        else
        {
            for (int i = 0; i < tempProcessStringBuffer; i++)
            {
                ToggleIgnoreArray(client, tempTargArray[i], 1);
            }
            return Plugin_Handled;
        }
    }
}

