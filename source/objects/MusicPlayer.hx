package objects;

import flixel.group.FlxGroup;
import flixel.ui.FlxBar;
import flixel.util.FlxStringUtil;

import states.FreeplayState;

/**
 * Music player used for Freeplay
 */
@:access(states.FreeplayState)
class MusicPlayer extends FlxGroup 
{
	public var instance:FreeplayState;

	public var playing(get, never):Bool;
	public var paused(get, never):Bool;

	public var playingMusic:Bool = false;
	public var curTime:Float;

	var songBG:FlxSprite;
	var songTxt:FlxText;
	var timeTxt:FlxText;
	var progressBG:FlxSprite;
	var progressBar:FlxBar;
	var playbackSymbols:Array<FlxText> = [];
	var playbackTxt:FlxText;

	var wasPlaying:Bool;

	var holdPitchTime:Float = 0;
	var playbackRate(default, set):Float = 1;

	public function new(instance:FreeplayState)
	{
		super();

		this.instance = instance;

		songBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, 100, 0xFF000000);
		songBG.alpha = 0.6;
		add(songBG);

		songTxt = new FlxText(FlxG.width * 0.7, 18, 0, "", 32);
		songTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT);
		add(songTxt);

		timeTxt = new FlxText(FlxG.width * 0.7, songTxt.y + 32, 0, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT);
		add(timeTxt);

		for (i in 0...2)
		{
			var text:FlxText = new FlxText();
			text.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
			text.text = '^';
			if (i == 1)
				text.flipY = true;
			text.visible = false;
			playbackSymbols.push(text);
			add(text);
		}

		progressBG = new FlxSprite(5, FlxG.height - 79).makeGraphic(FlxG.width - 10, 44, 0xFF000000);
		add(progressBG);
		
		progressBar = new FlxBar(10, FlxG.height - 69, LEFT_TO_RIGHT, FlxG.width - 20, 24, null, "", 0, Math.POSITIVE_INFINITY);
		progressBar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE);
		add(progressBar);

		playbackTxt = new FlxText(FlxG.width * 0.6, 20, 0, "", 32);
		playbackTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE);
		add(playbackTxt);

		switchPlayMusic();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!playingMusic)
		{
			return;
		}

		if (paused && !wasPlaying)
			songTxt.text = 'PLAYING: ' + instance.songs[FreeplayState.curSelected].songName + ' (PAUSED)';
		else
			songTxt.text = 'PLAYING: ' + instance.songs[FreeplayState.curSelected].songName;

		positionSong();

		if (instance.controls.UI_LEFT_P)
		{
			if (playing)
				wasPlaying = true;

			pauseOrResume();

			curTime = FlxG.sound.music.time - 1000;
			instance.holdTime = 0;

			if (curTime < 0)
				curTime = 0;

			FlxG.sound.music.time = curTime;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.time = curTime;
		}
		if (instance.controls.UI_RIGHT_P)
		{
			if (playing)
				wasPlaying = true;

			pauseOrResume();

			curTime = FlxG.sound.music.time + 1000;
			instance.holdTime = 0;

			if (curTime > FlxG.sound.music.length)
				curTime = FlxG.sound.music.length;

			FlxG.sound.music.time = curTime;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.time = curTime;
		}
	
		updateTimeTxt();

		if(instance.controls.UI_LEFT || instance.controls.UI_RIGHT)
		{
			instance.holdTime += elapsed;
			if(instance.holdTime > 0.5)
			{
				curTime += 40000 * elapsed * (instance.controls.UI_LEFT ? -1 : 1);
			}

			var difference:Float = Math.abs(curTime - FlxG.sound.music.time);
			if(curTime + difference > FlxG.sound.music.length) curTime = FlxG.sound.music.length;
			else if(curTime - difference < 0) curTime = 0;

			FlxG.sound.music.time = curTime;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.time = curTime;

			updateTimeTxt();
		}

		if(instance.controls.UI_LEFT_R || instance.controls.UI_RIGHT_R)
		{
			FlxG.sound.music.time = curTime;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.time = curTime;

			if (wasPlaying)
			{
				pauseOrResume(true);
				wasPlaying = false;
			}

			updateTimeTxt();
		}
		if (instance.controls.UI_UP_P)
		{
			holdPitchTime = 0;
			playbackRate += 0.05;
			setPlaybackRate();
		}
		else if (instance.controls.UI_DOWN_P)
		{
			holdPitchTime = 0;
			playbackRate -= 0.05;
			setPlaybackRate();
		}
		if (instance.controls.UI_DOWN || instance.controls.UI_UP)
		{
			holdPitchTime += elapsed;
			if (holdPitchTime > 0.6)
			{
				playbackRate += 0.05 * (instance.controls.UI_UP ? 1 : -1);
				setPlaybackRate();
			}
		}
		if (FreeplayState.vocals != null && FlxG.sound.music.time > 5)
		{
			var difference:Float = Math.abs(FlxG.sound.music.time - FreeplayState.vocals.time);
			if (difference >= 5 && !paused)
			{
				pauseOrResume();
				FreeplayState.vocals.time = FlxG.sound.music.time;
				pauseOrResume(true);
			}
		}
		updatePlaybackTxt();

		if (instance.touchPad.buttonC.justPressed || instance.controls.RESET)
		{
			playbackRate = 1;
			setPlaybackRate();

			FlxG.sound.music.time = 0;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.time = 0;

			updateTimeTxt();
		}
	}

	public function pauseOrResume(resume:Bool = false) 
	{
		if (resume)
		{
			FlxG.sound.music.resume();

			if (FreeplayState.vocals != null)
				FreeplayState.vocals.resume();
		}
		else 
		{
			FlxG.sound.music.pause();

			if (FreeplayState.vocals != null)
				FreeplayState.vocals.pause();
		}
		positionSong();
	}

	public function switchPlayMusic()
	{
		FlxG.autoPause = (!playingMusic && ClientPrefs.data.autoPause);
		active = visible = playingMusic;

		instance.scoreBG.visible = instance.diffText.visible = instance.scoreText.visible = !playingMusic; //Hide Freeplay texts and boxes if playingMusic is true
		songTxt.visible = timeTxt.visible = songBG.visible = playbackTxt.visible = progressBar.visible = progressBG.visible = playingMusic; //Show Music Player texts and boxes if playingMusic is true

		for (i in playbackSymbols)
			i.visible = playingMusic;
		
		holdPitchTime = 0;
		instance.holdTime = 0;
		playbackRate = 1;
		updatePlaybackTxt();

		if (playingMusic)
		{
			if (instance.controls.mobileC)
				instance.bottomText.text = "Press X to Pause / Press B to Exit / Press C to Reset the Song";
			else
				instance.bottomText.text = "Press SPACE to Pause / Press ESCAPE to Exit / Press R to Reset the Song";
			positionSong();
			
			progressBar.setRange(0, FlxG.sound.music.length);
			progressBar.setParent(FlxG.sound.music, "time");
			progressBar.numDivisions = 1600;

			updateTimeTxt();
		}
		else
		{
			progressBar.setRange(0, Math.POSITIVE_INFINITY);
			progressBar.setParent(null, "");
			progressBar.numDivisions = 0;

			instance.bottomText.text = instance.bottomString;
			instance.positionHighscore();
		}
		progressBar.updateBar();
	}

	function updatePlaybackTxt()
	{
		var text = "";
		if (playbackRate is Int)
			text = playbackRate + '.00';
		else
		{
			var playbackRate = Std.string(playbackRate);
			if (playbackRate.split('.')[1].length < 2) // Playback rates for like 1.1, 1.2 etc
				playbackRate += '0';

			text = playbackRate;
		}
		playbackTxt.text = text + 'x';
	}

	function positionSong() 
	{
		songTxt.x = 10;
		timeTxt.x = songBG.x;
		playbackTxt.x = (FlxG.width - playbackTxt.width) / 2;
		playbackTxt.y = playbackTxt.height;

		for (i in 0...2)
		{
			var text = playbackSymbols[i];
			text.x = playbackTxt.x + playbackTxt.width / 2 - 10;
			text.y = playbackTxt.y;

			if (i == 0)
				text.y -= playbackTxt.height;
			else
				text.y += playbackTxt.height;
		}
	}

	function updateTimeTxt()
	{
		var text = FlxStringUtil.formatTime(FlxG.sound.music.time / 1000, false) + ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000, false);
		timeTxt.text = '< ' + text + ' >';
	}

	function setPlaybackRate() 
	{
		FlxG.sound.music.pitch = playbackRate;
		if (FreeplayState.vocals != null)
			FreeplayState.vocals.pitch = playbackRate;
	}

	function get_playing():Bool 
	{
		return FlxG.sound.music.playing;
	}

	function get_paused():Bool 
	{
		@:privateAccess return FlxG.sound.music._paused;
	}

	function set_playbackRate(value:Float):Float 
	{
		var value = FlxMath.roundDecimal(value, 2);
		if (value > 3)
			value = 3;
		else if (value <= 0.25)
			value = 0.25;
		return playbackRate = value;
	}
}
