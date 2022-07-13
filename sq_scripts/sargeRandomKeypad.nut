class sargeKeypadBase extends SqRootScript
{
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
	}

	//Run only once ever, not per map
	function Init()
	{
		DisableKeycode();
	}
	
	function DisableKeycode()
	{
		local code = GetProperty("KeypadCode");
		SetData("OriginalCode",code);
		SetProperty("KeypadCode", code + 100000);
		SetData("ShowCode", FALSE);
		print ("Changed code for keypad to " + (code + 100000));
	}
	
	function Unlock()
	{
		local original = GetData("OriginalCode")
		print ("Resetting code to " + original);
		SetProperty("KeypadCode", original);
		SetData("ShowCode", TRUE);
	}
	
	//Stop us from displaying the "Code: blahblah" messages when frobbing on opened keypads
	function OnKeypadDone()
	{
		SetData("ShowCode", FALSE);
	}
	
	function OnReset() {
		ClearData("Setup");
	}

	function OnNetOpened() {
		SetData("ShowCode", FALSE);
	}

	function OnHackSuccess() {
		SetData("ShowCode", FALSE);
	}
	
	//If we know the code, tell us what it is
	//This is similar to how modern games like Prey tell you the code when using a keypad
	//once you have found it in the world
	function OnFrobWorldEnd()
	{
		local code = GetProperty("KeypadCode");
		
		if (!GetData("ShowCode"))
			return;	
		
		ShockGame.AddText("Code: " + code, null);
	}
}


// ================================================================================
// Sets a keypad to have a random code
class sargeRandomKeypad extends sargeKeypadBase
{
	function OnBeginScript()
	{
		base.OnBeginScript();
		if (HasProperty("QBName"))
		{
			Quest.SubscribeMsg(self, GetProperty("QBName"), eQuestDataType.kQuestDataCampaign);
			OnQuestChange();
		}
	}
	
	function OnQuestChange()
	{
		if (Quest.Get(GetProperty("QBName")) > 0)
			Unlock();
	}
	
	function OnEndScript()
	{
		if (HasProperty("QBName"))
		{
			Quest.UnsubscribeMsg(self, GetProperty("QBName"));
		}
	}

}

class sargeTransmitterKeypad extends sargeKeypadBase
{
	function Init()
	{
		base.Init();
		local requiredQuestupdates = getParam("RequiredUpdates",0);
		SetData("RequiredQuestUpdates",requiredQuestupdates);
		print ("required quest updates:" + requiredQuestupdates);
	}
	
	function OnBeginScript()
	{
		base.OnBeginScript();
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