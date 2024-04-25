// ================================================================================
// Base class for handling keypad functionality
class sargeKeypadBase extends SqRootScript
{
    static function GetObjectName(obj)
    {
        local name = Object.GetName(obj);
        if (name == "")
            name = ShockGame.GetArchetypeName(obj);
        return name;
    }

	static function PrintDebug(msg)
	{
        if (getParam("debug",0))
        {
    		print ("[" + self + "] " + GetObjectName(self) + "> " + msg);
		    ShockGame.AddText("[" + self + "] " + GetObjectName(self) + "> " + msg, null);
        }
	}

	// fetch a parameter or return default value
	// blatantly stolen from RSD
	function getParam(key, defVal)
	{
		return key in userparams() ? userparams()[key] : defVal;
	}
	
	function OnBeginScript()
	{

		if (!GetData("Setup"))
		{
			Init();
			SetData("Setup",TRUE);
		}
		MapLoaded();
	}

	//override this
	function MapLoaded()
	{
	}

	//Run only once ever per map, not on reload or reenter
	function Init()
	{
        //don't change codes if we're told not to
        if (getParam("noChangeCode",0))
        {
		    local code = GetProperty("KeypadCode");
            UpdateHUDString(code);
            PrintDebug("noChangeCode - Aborting!");
        }
        else
        {
    		DisableKeycode();
        }
	}
	
	function DisableKeycode()
	{
		local code = GetProperty("KeypadCode");

		SetData("OriginalCode",code);
		SetProperty("KeypadCode", code + 100000);
		SetData("Locked", TRUE);
		PrintDebug("Changed code for keypad to " + (code + 100000));
	}
	
	function Unlock()
	{
		if (!GetData("Locked"))
			return;	
			
        PrintDebug("Unlocking...");
		
        local original = GetData("OriginalCode")
        PrintDebug("Resetting code to " + original);
        SetProperty("KeypadCode", original);
        SetData("Locked", FALSE);
        UpdateHUDString(original);
	}

    function UpdateHUDString(original)
    {
        local useString = Data.GetObjString(self, "huduse");

        if (useString == "")
            return;

		local period = useString.find(".");
        if (period)
    		useString = useString.slice(0, period);

        SetProperty("HUDUse", ": \"" + useString + ": " + format("%05d", original) + "\"");
    }
	
	function OnNetOpened() {
        Unlock();
	}

	function OnHackSuccess() {
        Unlock();
	}
	
	function OnReset() {
		Init();
		OnQuestChange();
	}
	
}


// ================================================================================
// Setup keypads to be unopenable until the right quest var is set
class sargeRandomKeypad extends sargeKeypadBase
{
	QB = null;

	function MapLoaded()
	{
		QB = GetData("QB");
		
		if (QB)
		{
            PrintDebug("Subscribing to QB " + QB);
			Quest.SubscribeMsg(self, QB, eQuestDataType.kQuestDataCampaign);
			OnQuestChange();
		}
        else
        {
            PrintDebug("No QB!");
        }

	}

	function Init()
	{
		base.Init();
		
        local based;
		if (HasProperty("QBName"))
		{
			QB = GetProperty("QBName");
            based = "based on QBName Property";
		}
		else
		{
			QB = GetQB();
            based = "based on GetQB";
		}
		
		if (QB)
		{
			PrintDebug("Setting QB to " + QB + " " + based);
			SetData("QB",QB);
		}
	}

	//blatantly stolen from ZylonBane
	function GetQB()
	{
        if (!GetData("OriginalCode"))
            return;

		local code = format("%05d", GetData("OriginalCode"));
		for (local deck = 1; deck <= 9; deck++)
		{
			for (local note = 1; note <= 32; note++)
			{
				local qb = "Note_" + deck + "_" + note;
				if (Data.GetString("notes", qb).find(code))
				{
					return qb;
				}
			}
		}
		return false;
	}
	
	function OnQuestChange()
	{
		if (Quest.Get(QB) > 0)
			Unlock();
	}
	
	function OnEndScript()
	{
		if (QB)
		{
			Quest.UnsubscribeMsg(self, QB);
		}
	}

}

// ================================================================================
// Setup transmitter in rec1 to be unusable until the right quest vars are set
class sargeTransmitterKeypad extends sargeKeypadBase
{
	function Init()
	{
		base.Init();
		local requiredQuestupdates = getParam("RequiredUpdates",0);
		SetData("RequiredQuestUpdates",requiredQuestupdates);
		PrintDebug("Transmitter: Required quest updates: " + requiredQuestupdates);
	}
	
	function MapLoaded()
	{
		Subscribe();
		OnQuestChange();
	}
	
	function OnEndScript()
	{
		Unsubscribe();
	}
	
	function Subscribe()
	{
		local param_pre = getParam("QBPrefix","");
		local param_start = getParam("QBStart",0);
		local param_num = getParam("QBNum",0);
		if (param_pre != "")
		{
            for (local i = param_start;i <= param_start + param_num;i++)
            {
                local param = param_pre + i;
                PrintDebug("Subscribing to " + param);
                Quest.SubscribeMsg(self, param, eQuestDataType.kQuestDataCampaign);
            }
		}
	}
	
	function Unsubscribe()
	{
		local param_pre = getParam("QBPrefix","");
		local param_start = getParam("QBStart",0);
		local param_num = getParam("QBNum",0);
        for (local i = param_start;i <= param_start + param_num;i++)
        {
            local param = param_pre + i;
            PrintDebug("Unsubscribing from " + param);
            Quest.UnsubscribeMsg(self, param);
		}
	}
	
	function OnQuestChange()
	{
		local count = 0;
        local param_pre = getParam("QBPrefix","");
		local param_start = getParam("QBStart",0);
		local param_num = getParam("QBNum",0);
		local required = GetData("RequiredQuestUpdates");

        for (local i = param_start;i <= param_start + param_num;i++)
        {
            local param = param_pre + i;
            local value = Quest.Get(param);
            count += value;
        }
		
		if (count >= required)
		{
			Unlock();
			PrintDebug("Transmitter Unlocked");
		}
		else
		{
			PrintDebug("remaining quest updates: " + (required - count));
		}
	}	
}
