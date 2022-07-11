// ================================================================================
// Sets a keypad to have a random code
class sargeRandomKeypad extends SqRootScript {
	function OnSim() {
		local code = GetProperty("KeypadCode");
		SetProperty("KeypadCode", code + 100000);
		print ("Changed code for keypad to " + (code + 100000));
	}
	
	function OnTurnOn() {
		local code = GetProperty("KeypadCode");
		print ("Resetting code to " + (code - 100000));
		SetProperty("KeypadCode", code - 100000);
	}
	
	//If we know the code, tell us what it is
	//This is similar to how modern games like Prey tell you the code when using a keypad
	//once you have found it in the world
	function OnFrobWorldEnd() {
		local code = GetProperty("KeypadCode");
		
		if (code >= 100000)
			return;	
		
		ShockGame.AddText("Code: " + code, null);
	}
}