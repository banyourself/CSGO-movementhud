static KeyValues configKv;

static char configPath[] = "cfg/sourcemod/movementhud-defaults.cfg";

void OnPluginStart_PreferencesDefaults()
{
    configKv = new KeyValues("MovementHUD-Defaults");

    // A malformed defaults file makes KeyValues emit a server-console error.
    // Validate this flat configuration before importing it so invalid files are
    // regenerated cleanly from the built-in defaults.
    if (HasValidDefaultsConfig())
    {
        configKv.ImportFromFile(configPath);
    }
    else if (FileExists(configPath))
    {
        LogMessage("[MovementHUD] Invalid %s detected. It will be rebuilt with valid default values.", configPath);
    }
}

bool GetPreferenceDefault(char id[MHUD_MAX_ID], char value[MHUD_MAX_VALUE])
{
    if (!HasDefaultForPreferenceId(id))
    {
        return false;
    }

    configKv.GetString(id, value, sizeof(value));
    return true;
}

void SetPreferenceDefault(Preference preference)
{
    bool exists = HasDefaultForPreferenceId(preference.Id);
    if (exists)
    {
        return;
    }

    configKv.SetString(preference.Id, preference.DefaultValue);
    configKv.ExportToFile(configPath);
}

static bool HasDefaultForPreferenceId(const char id[MHUD_MAX_ID])
{
    bool exists = configKv.JumpToKey(id);
    if (!exists)
    {
        return false;
    }

    configKv.GoBack();
    return true;
}

static bool HasValidDefaultsConfig()
{
    if (!FileExists(configPath))
    {
        return false;
    }

    File file = OpenFile(configPath, "r");
    if (file == null)
    {
        return false;
    }

    char line[256];
    bool foundRoot = false;
    bool foundOpeningBrace = false;
    bool foundClosingBrace = false;

    while (!file.EndOfFile() && file.ReadLine(line, sizeof(line)))
    {
        TrimString(line);

        // Windows editors commonly prepend a UTF-8 byte-order mark. It is not
        // part of the KeyValues root name, so remove it before validation.
        int length = strlen(line);
        if (!foundRoot && length >= 3 && line[0] == 0xEF && line[1] == 0xBB && line[2] == 0xBF)
        {
            for (int i = 0; i <= length - 3; i++)
            {
                line[i] = line[i + 3];
            }
        }

        if (line[0] == '\0' || StrContains(line, "//") == 0)
        {
            continue;
        }

        if (!foundRoot)
        {
            if (!StrEqual(line, "\"MovementHUD-Defaults\""))
            {
                delete file;
                return false;
            }

            foundRoot = true;
            continue;
        }

        if (!foundOpeningBrace)
        {
            if (!StrEqual(line, "{"))
            {
                delete file;
                return false;
            }

            foundOpeningBrace = true;
            continue;
        }

        if (StrEqual(line, "}"))
        {
            foundClosingBrace = true;
            continue;
        }

        if (foundClosingBrace || !IsValidDefaultPair(line))
        {
            delete file;
            return false;
        }
    }

    delete file;
    return foundRoot && foundOpeningBrace && foundClosingBrace;
}

static bool IsValidDefaultPair(const char[] line)
{
    int quoteCount = 0;
    int length = strlen(line);

    for (int i = 0; i < length; i++)
    {
        if (line[i] == '"')
        {
            quoteCount++;
        }
    }

    return quoteCount >= 4 && quoteCount % 2 == 0;
}
