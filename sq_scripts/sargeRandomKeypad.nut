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
		if (GetData("Done"))
			return;
		
		DisableKeycode();
		
	}
	
	function DisableKeycode()
	{
		local code = GetProperty("KeypadCode");
		SetData("OriginalCode",code);
		SetProperty("KeypadCode", code + 100000);
		print ("Changed code for keypad to " + (code + 100000));
		SetData("Done",TRUE);
	}
	
	function Unlock()
	{
		local original = GetData("OriginalCode")
		print ("Resetting code to " + original);
		SetProperty("KeypadCode", original);
		SetData("CodeKnown", TRUE);
	}
	
	//Stop us from displaying the "Code: blahblah" messages when frobbing on opened keypads
	function OnKeypadDone()
	{
		SetData("DontShowCode", message().code == GetProperty("KeypadCode"));
	}
	
	function OnReset() {
		ClearData("DontShowCode");
		ClearData("CodeKnown");
		ClearData("Done");
		DisableKeycode();
	}

	function OnNetOpened() {
		SetData("DontShowCode", TRUE);
	}

	function OnHackSuccess() {
		SetData("DontShowCode", TRUE);
	}
	
	//If we know the code, tell us what it is
	//This is similar to how modern games like Prey tell you the code when using a keypad
	//once you have found it in the world
	function OnFrobWorldEnd()
	{
		local code = GetProperty("KeypadCode");
		
		if (!GetData("CodeKnown") || GetData("DontShowCode"))
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
	
	function OnEndScript()
	{
		if (HasProperty("QBName"))
			Quest.UnsubscribeMsg(self, GetProperty("QBName"));
	}
	
	function OnQuestChange()
	{
		if (Quest.Get(GetProperty("QBName")) > 0)
			Unlock();
	}

}

class sargeTransmitterKeypad extends sargeKeypadBase
{
	function OnBeginScript()
	{
		base.OnBeginScript();
		Subscribe("QB1Name");
		Subscribe("QB2Name");
		Subscribe("QB3Name");
		Subscribe("QB4Name");
		
		local requiredQuestupdates = getParam("RequiredUpdates",0);
		SetData("RequiredQuestUpdates",requiredQuestupdates);
		print ("required quest updates:" + requiredQuestupdates);
		
		OnQuestChange();
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
	
	function OnQuestChange()
	{
		local count = GetData("RequiredQuestUpdates") - 1;
		
		if (count <= 0)
		{
			Unlock();
		}
		else
		{
			SetData("RequiredQuestUpdates",count);
		}
		print ("remaining quest updates: " + (count));
	}	
}