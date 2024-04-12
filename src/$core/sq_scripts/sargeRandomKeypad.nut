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
        //if (getParam("debug",0))
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
		    SetData("ShowCode", TRUE);
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
		SetData("ShowCode", FALSE);
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
        SetData("ShowCode", TRUE);
        UpdateHUDString(original);
	}

    function UpdateHUDString(original)
    {
        local useString = Data.GetObjString(self, "huduse");
		local period = useString.find(".");
        if (period)
    		useString = useString.slice(0, period);

        SetProperty("HUDUse", ": \"" + useString + ": " + format("%05d", original) + "\"");
    }
	
	//Stop us from displaying the "Code: blahblah" messages when frobbing on opened keypads
	function OnKeypadDone()
	{
		SetData("ShowCode", FALSE);
		SetData("Locked", FALSE);
	}
	
	function OnNetOpened() {
		SetData("ShowCode", FALSE);
		SetData("Locked", FALSE);
	}

	function OnHackSuccess() {
		SetData("ShowCode", FALSE);
		SetData("Locked", FALSE);
	}
	
	function OnReset() {
		Init();
		OnQuestChange();
	}
	
	//If we know the code, tell us what it is
	//This is similar to how modern games like Prey tell you the code when using a keypad
	//once you have found it in the world
    /*
	function OnFrobWorldEnd()
	{
		if (!GetData("ShowCode"))
			return;	
	
		local code = GetProperty("KeypadCode");
		ShockGame.AddText("Code: " + code, null);
	}
    */
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
		print ("required quest updates:" + requiredQuestupdates);
	}
	
	function MapLoaded()
	{
		Subscribe("QB1Name");
		Subscribe("QB2Name");
		Subscribe("QB3Name");
		Subscribe("QB4Name");
		OnQuestChange();
	}
	
	function OnEndScript()
	{
		Unsubscribe("QB1Name");
		Unsubscribe("QB2Name");
		Unsubscribe("QB3Name");
		Unsubscribe("QB4Name");
	}
	
	function Subscribe(parameter)
	{
		local param_value = getParam(parameter,0);
		if (param_value)
		{
			print ("Subscribing to " + parameter + ": " + param_value);
			Quest.SubscribeMsg(self, param_value, eQuestDataType.kQuestDataCampaign);
		}
	}
	
	function Unsubscribe(parameter)
	{
		local param_value = getParam(parameter,0);
		if (param_value)
		{
			print ("Unsubscribing from " + parameter + ": " + param_value);
			Quest.UnsubscribeMsg(self, param_value);
		}
	}
	
	function OnQuestChange()
	{
	
		local first = Quest.Get(getParam("QB1Name",0));
		local second = Quest.Get(getParam("QB2Name",0));
		local third = Quest.Get(getParam("QB3Name",0));
		local fourth = Quest.Get(getParam("QB4Name",0));
	
		local count = first + second + third + fourth;
		local required = GetData("RequiredQuestUpdates");
		
		if (count >= required)
		{
			Unlock();
			print ("Transmitter Unlocked");
		}
		else
		{
			print ("remaining quest updates: " + (required - count));
		}
	}	
}
