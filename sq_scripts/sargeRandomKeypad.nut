// ================================================================================
// Sets a keypad to have a random code
class sargeRandomKeypad extends SqRootScript {
		function OnFrobWorldEnd() {
			local newCode = Data.RandInt(10000,55555);
			SetProperty("KeypadCode",newCode);
			print ("aaaahhhh: " + newCode);
		}
}