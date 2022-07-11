// ================================================================================
// Sets a keypad to have a random code
class sargeRandomKeypad extends SqRootScript
{
	function OnSim()
	{
		local code = GetProperty("KeypadCode");
		SetData("OriginalCode",code);
		SetProperty("KeypadCode", code + 100000);
		print ("Changed code for keypad to " + (code + 100000));
	}
	
	function OnTurnOn()
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
		local original = GetData("OriginalCode")
		
		if (!GetData("CodeKnown") || GetData("DontShowCode"))
			return;	
		
		ShockGame.AddText("Code: " + code, null);
	}
}