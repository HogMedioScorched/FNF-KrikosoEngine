package options;

import flixel.FlxObject;
import states.MainMenuState;
import backend.StageData;
import flixel.addons.transition.FlxTransitionableState;
import mobile.substates.MobileControlSelectSubState;
#if (target.threaded)
import sys.thread.Thread;
import sys.thread.Mutex;
#end
import flixel.math.FlxMath;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay', 'Mobile Options', 'Mobile Controls', 'Krikoso Engine'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	#if (target.threaded) var mutex:Mutex = new Mutex(); #end

	function openSelectedSubstate(label:String) {
		persistentUpdate = false;
		if (label != "Adjust Delay and Combo") removeTouchPad();
		switch(label) {
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Mobile Options':
				openSubState(new mobile.options.MobileOptionsSubState());
			case 'Mobile Controls':
				openSubState(new MobileControlSelectSubState());
			case 'Krikoso Engine':
				openSubState(new options.KrikosoOptionsSubState());
		}
	}

	var selectorLeft:Alphabet;

	override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(200, 200, options[i], true);
			optionText.screenCenter(Y);
			optionText.y += (75 * (i - curSelected));
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(135, 200, '>', true);
		add(selectorLeft);

		var titleBox:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 60, FlxColor.BLACK);
		titleBox.alpha = 0.6;
		add(titleBox);

		var titleText:Alphabet = new Alphabet(10, 10, "OPTIONS", true);
		titleText.setScale(0.6);
		titleText.alpha = 0.6;
		add(titleText);

		changeSelection();
		ClientPrefs.saveSettings();

		addTouchPad("UP_DOWN", "A_B");

		super.create();
		
	}

	override function closeSubState() {
		super.closeSubState();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		ClientPrefs.saveSettings();
		ClientPrefs.loadPrefs();
		controls.isInSubstate = false;
        removeTouchPad();
		addTouchPad("UP_DOWN", "A_B");
		persistentUpdate = true;
	}

    var exiting:Bool = false;
	override function update(elapsed:Float) {
		super.update(elapsed);

		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));

		var idx:Int = 0;
		for (item in grpOptions.members) {
			item.y = 200 + (75 * (idx - lerpSelected));
			idx++;
		}

		if (!exiting) {
		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		if (controls.BACK) {
                        exiting = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else MusicBeatState.switchState(new MainMenuState());
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				//selectorLeft.x = item.x - 63;
				//selectorLeft.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
