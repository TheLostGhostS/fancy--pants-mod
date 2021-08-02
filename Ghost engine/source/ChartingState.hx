package;

import openfl.display3D.textures.TextureBase;
import Movement.EffectParams;
import Movement.SpriteEffect;
import flixel.addons.ui.interfaces.IEventGetter;
import io.newgrounds.objects.events.Result.GetCurrentVersionResult;
import flixel.addons.ui.FlxUIText;
import haxe.zip.Writer;
import Conductor.BPMChangeEvent;
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

using StringTools;

class ChartingState extends MusicBeatState
{
	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;

	public static var lastSection:Int = 0;

	var bpmTxt:FlxText;

	var strumLine:FlxSprite;
	var curSong:String = 'Dadbattle';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;
	var writingNotesText:FlxText;
	var prefabNotesText:FlxText;
	var highlight:FlxSprite;

	var GRID_SIZE:Int = 40;

	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;

	var curRenderedEffects:FlxTypedGroup<SpriteEffect>;

	var curRenderedSustains:FlxTypedGroup<FlxSprite>;

	var _easeInfo:Array<String>;

	var _currentEaseIndex:Int = 0;
	var _currentEaseType:String = "quad";
	var _currentEaseDirection:String = "In";


	var gridBG:FlxSprite;

	var _song:SwagSong;

	var typingShit:FlxInputText;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;

	var curSelectedEffect:EffectParams;

	var tempBpm:Int = 0;
	var gridBlackLine:FlxSprite;
	var vocals:FlxSound;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;


	private var lastNote:Note;

	private var prefab:Bool;

	public var notePrefabSelected:Int = 0;

	public var effectPrefabSelected:Int = 0;


	override function create()
	{
		curSection = lastSection;

		prefab = false;

		if(FlxG.save.data.notePrefab[0] == null){
			FlxG.save.data.notePrefab[0] = {
				hold: 0,
				speed: 1,
				type: 0

			};

		}

		if(FlxG.save.data.effectPrefab[0] == null){
			FlxG.save.data.effectPrefab[0] = {
				quantity: 0,
				duration: 0,
				target: 'x',
				all: true,
				set: false,
				way: 'none'
			};


		}

		
		notePrefabSelected = FlxG.save.data.prefabNote;

		
		effectPrefabSelected = FlxG.save.data.prefabEffect;

		FlxG.save.flush();


		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		add(gridBG);

		gridBlackLine = new FlxSprite(gridBG.x + gridBG.width / 2).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		add(gridBlackLine);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedEffects = new FlxTypedGroup<SpriteEffect>();

		_easeInfo = [
			"quadIn", "quadOut", "quadInOut",

			 "cubeIn", "cubeOut","cubeInOut",

			"quartIn","quartOut","quartInOut",

			"quintIn","quintOut","quintInOut",

			"sineIn","sineOut","sineInOut",

			"bounceIn","bounceOut","bounceInOut",

			"circIn","circOut", "circInOut",

			"expoIn","expoOut","expoInOut",

			"backIn","backOut","backInOut",

			"elasticIn", "elasticOut","elasticInOut",

			"smoothStepIn","smoothStepOut",
			"smoothStepInOut","smootherStepIn",

			"smootherStepOut","smootherStepInOut",

			 "none"
		];



		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
		{
			_song = {
				song: 'Test',
				notes: [],
				bpm: 150,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				speed: 1,
				validScore: false
			};
		}
		
 
		leftIcon = new HealthIcon(_song.player1);
		rightIcon = new HealthIcon(_song.player2);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(0, -100);
		rightIcon.setPosition(gridBG.width / 2, -100);


		FlxG.mouse.visible = true;
		FlxG.save.bind('funkin', 'ninjamuffin99');

		tempBpm = _song.bpm;

		addSection();

		// sections = _song.notes;

		

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4);
		add(strumLine);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2;
		UI_box.y = 20;
		add(UI_box);

		addSongUI();
		addNoteUI();
		addSectionUI();
		


		add(curRenderedNotes);
		add(curRenderedEffects);
		add(curRenderedSustains);

		updateGrid();
		

		super.create();
	}

	function addSongUI():Void
	{
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			trace('CHECKED!');
		};

		var check_mute_inst = new FlxUICheckBox(10, 200, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function()
		{
			loadSong(_song.song);
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			loadJson(_song.song.toLowerCase());
		});

		
		var restart = new FlxButton(10,140,"Reset", function()
            {
                for (ii in 0..._song.notes.length)
                {
                    
					_song.notes[ii].sectionNotes = [];
					_song.notes[ii].effects = [];
					
                }
                resetSection(true);
			});
		
		//Ghost reporting here just to say hello and take care of yourself :3

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'load autosave', loadAutosave);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
			
		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 0.1, 1, 1.0, 5000.0, 1);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

		var player1DropDown = new FlxUIDropDownMenu(10, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)]; 
			
			//PlayState.dad
			updateHeads();
			//comment for future reference
		});
		player1DropDown.selectedLabel = _song.player1;
		

		var player2DropDown = new FlxUIDropDownMenu(140, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)]; 
			updateHeads();
			
		});

		player2DropDown.selectedLabel = _song.player2;
		

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);
		tab_group_song.add(restart);
		tab_group_song.add(check_voices);
		tab_group_song.add(check_mute_inst);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(player2DropDown);

		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		FlxG.camera.follow(strumLine);
	}

	var tab_group_section:FlxUI;

	var stepperLength:FlxUINumericStepper;
	var lockPos:FlxUICheckBox;
	var Swap:FlxUICheckBox;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;
	var stepperSpawn:FlxUINumericStepper;
	var stepperSecSpeed:FlxUINumericStepper;

	function addSectionUI():Void
	{
		tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSection].lengthInSteps;
		stepperLength.name = "section_length";

		stepperSectionBPM = new FlxUINumericStepper(10, 90, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		stepperSpawn = new FlxUINumericStepper(10, 200, 50, 1500, 50, 5000);
		stepperSpawn.value = 2000;
		stepperSpawn.name = 'spawn_change';

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);

		var copyButton:FlxButton = new FlxButton(10, 130, "Copy last section", function()
		{
			copySection(Std.int(stepperCopy.value));
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear", clearSection);

		var swapSection:FlxButton = new FlxButton(10, 170, "Swap section", function()
		{	

			if(! effects.checked){
				for (i in 0..._song.notes[curSection].sectionNotes.length)
				{	
					var note = _song.notes[curSection].sectionNotes[i];
					note[1] = (note[1] + 4) % 8;
					_song.notes[curSection].sectionNotes[i] = note;
				}
			}else{
				for(i in 0..._song.notes[curSection].effects.length){
					var effect = _song.notes[curSection].effects[i];
					effect.player = !effect.player;
					_song.notes[curSection].effects[i] = effect;

				}

			}


			updateGrid();
		});

		check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = true; 
		// _song.needsVoices = check_mustHit.checked;



		lockPos = new FlxUICheckBox(10, 50, null, null, "Lock Grid change",100);
		lockPos.name = 'lock_position';
		lockPos.checked = false; 

		Swap = new FlxUICheckBox(10, 30, null, null, "Swap",100);
		Swap.name = 'Swap';
		Swap.checked = false; 
		


		check_altAnim = new FlxUICheckBox(10, 400, null, null, "Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, 70, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		stepperSecSpeed = new FlxUINumericStepper(10, 220, 0.1, 1, 0.5, 10, 1);
		stepperSecSpeed.value = 1;
		stepperSecSpeed.name = 'section_speed';

		tab_group_section.add(stepperLength);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(stepperSpawn);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(lockPos);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(swapSection);
		tab_group_section.add(stepperSecSpeed);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;

	var stepperSpeed:FlxUINumericStepper;

	var stepperType:FlxUINumericStepper;

	var effects:FlxUICheckBox;

	var adding:FlxUICheckBox;

	var setting:FlxUICheckBox;

	var effectLength:FlxUINumericStepper;

	var easeTypeDropDown:FlxUIDropDownMenu;

	var easeDirection:FlxUIDropDownMenu;

	var effectQuant:FlxUINumericStepper;

	var modifierType:FlxUIDropDownMenu;

	var tab_group_note:FlxUI;


	
	function addNoteUI():Void
	{
		tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		prefabNotesText = new FlxUIText(10,400, 0, "");
		prefabNotesText.setFormat("Arial",15,FlxColor.WHITE,FlxTextAlign.LEFT,FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);

		writingNotesText = new FlxUIText(20,100, 0, "");
		writingNotesText.setFormat("Arial",20,FlxColor.WHITE,FlxTextAlign.LEFT,FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * _song.notes[curSection].lengthInSteps * 4);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		stepperSpeed = new FlxUINumericStepper(10, 30, .1, 1, .5, 10, 1);
		stepperSpeed.value = 1;
		stepperSpeed.name = 'note_speed';

		stepperType = new FlxUINumericStepper(10, 50, 1, 0, 0, 2, 0);
		stepperType.value = 0;
		stepperType.name = 'note_type';

		effectLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet, 0, 0, (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps * 8));
		effectLength.value = 0;
		effectLength.name = 'effect_Length';

		effectQuant = new FlxUINumericStepper(10, 30, 10, 0, -5000, 5000);
		effectQuant.value = 0;
		effectQuant.name = 'effect_Quant';

		var easeTypes:Array<String> = [
			"quad", "cube", "quart", "quint", "sine", "bounce", "circ", "expo", "back", "elastic", "smoothStep", "smootherStep", "none"
		];

		//var header = new FlxUIDropDownHeader(100);
		easeTypeDropDown = new FlxUIDropDownMenu(10, 50, FlxUIDropDownMenu.makeStrIdLabelArray(easeTypes), easeUpdate, new FlxUIDropDownHeader(100));
		easeTypeDropDown.header.text.text = "none"; // Initialize header with correct value
		easeTypeDropDown.dropDirection = Down;

		var easeDirections:Array<String> = ["In", "Out", "InOut"];

		easeDirection = new FlxUIDropDownMenu(120, 50, FlxUIDropDownMenu.makeStrIdLabelArray(easeDirections), easeUpdate, new FlxUIDropDownHeader(100));
		easeDirection.header.text.text = "Out"; // Initialize header with correct value
		easeDirection.dropDirection = Down;

		var modifier:Array<String> = ["x", "y", "spriteRot", "incoming", "pivotRot", "radius", "alpha"];

		modifierType = new FlxUIDropDownMenu(10, 80, FlxUIDropDownMenu.makeStrIdLabelArray(modifier), targetUpdate, new FlxUIDropDownHeader(100));
		modifierType.header.text.text = "x"; // Initialize header with correct value
		modifierType.dropDirection = Down;

		adding = new FlxUICheckBox(10, 330, null, null, "All",100);
		adding.name = 'toggle_all';
		adding.checked = false;

		setting = new FlxUICheckBox(10, 350, null, null, "Set",100);
		setting.name = 'toggle_set';
		setting.checked = false;

		effects = new FlxUICheckBox(10, 400, null, null, "Effects",100);
		effects.name = 'toggle_effects';//'Effects'
		effects.checked = false;


		tab_group_note.add(writingNotesText);
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(stepperSpeed);
		tab_group_note.add(stepperType);
		tab_group_note.add(prefabNotesText);

		//tab_group_note.add(effectLength);
		//tab_group_note.add(effectQuant);
		//tab_group_note.add(adding);
		//tab_group_note.add(setting);
		//tab_group_note.add(modifierType);
		//tab_group_note.add(easeTypeDropDown);
		//tab_group_note.add(easeDirection);
		
		

		tab_group_note.add(effects);

		UI_box.addGroup(tab_group_note);
	}

	function loadSong(daSong:String):Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		FlxG.sound.playMusic(Paths.inst(daSong), 0.6);

		// WONT WORK FOR TUTORIAL OR TEST SONG!!! REDO LATER
		vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));
		FlxG.sound.list.add(vocals);

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.onComplete = function()
		{
			vocals.pause();
			vocals.time = 0;
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		};
	}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
		/* 
			var loopCheck = new FlxUICheckBox(UI_box.x + 10, UI_box.y + 50, null, null, "Loops", 100, ['loop check']);
			loopCheck.checked = curNoteSelected.doesLoop;
			tooltips.add(loopCheck, {title: 'Section looping', body: "Whether or not it's a simon says style section", style: tooltipType});
			bullshitUI.add(loopCheck);

		 */
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':

					
					_song.notes[curSection].mustHitSection = check.checked;

					updateHeads();
					

				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[curSection].altAnim = check.checked;

				case 'Lock Grid change':
					if(check.checked){

						tab_group_section.remove(check_mustHitSection);
						tab_group_section.add(Swap);

					}else{
						
						tab_group_section.remove(Swap);
						tab_group_section.add(check_mustHitSection);

					}
					updateGrid();
					updateHeads();

				case 'Swap':
					updateGrid();
					updateHeads();
				case 'Effects':
					updateGrid();
					updateHeads();
					if(writingNotes){
						writingNotes = false;

					}

					if(check.checked){

						tab_group_note.remove(writingNotesText);
						tab_group_note.remove(stepperSusLength);
						tab_group_note.remove(stepperSpeed);
						tab_group_note.remove(stepperType);

						tab_group_note.add(effectLength);
						tab_group_note.add(effectQuant);
						tab_group_note.add(adding);
						tab_group_note.add(setting);
						tab_group_note.add(modifierType);
						tab_group_note.add(easeTypeDropDown);
						tab_group_note.add(easeDirection);

					}else{

						tab_group_note.add(writingNotesText);
						tab_group_note.add(stepperSusLength);
						tab_group_note.add(stepperSpeed);
						tab_group_note.add(stepperType);

						tab_group_note.remove(effectLength);
						tab_group_note.remove(effectQuant);
						tab_group_note.remove(adding);
						tab_group_note.remove(setting);
						tab_group_note.remove(modifierType);
						tab_group_note.remove(easeTypeDropDown);
						tab_group_note.remove(easeDirection);

					}
				case 'All':	
					if(!prefab){
						if(curSelectedEffect != null){
							curSelectedEffect.all = check.checked;
							updateGrid();
						}
					}else{
						if(FlxG.save.data.effectPrefab[effectPrefabSelected] != null){
							FlxG.save.data.effectPrefab[effectPrefabSelected].all = check.checked;
							updateGrid();
						}

					}
				case 'Set':
					if(!prefab){
						if(curSelectedEffect != null){
							curSelectedEffect.set = check.checked;
							updateGrid();
						}
					}else{
						if(FlxG.save.data.effectPrefab[effectPrefabSelected] != null){
							FlxG.save.data.effectPrefab[effectPrefabSelected].set = check.checked;
							updateGrid();
						}
					}
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_length')
			{
				if (nums.value <= 4)
					nums.value = 4;
				_song.notes[curSection].lengthInSteps = Std.int(nums.value);
				updateGrid();
			}
			else if (wname == 'song_speed')
			{
				if (nums.value <= 0)
					nums.value = 0;
				_song.speed = nums.value;
			}
			else if (wname == 'section_speed')
			{
				if (nums.value <= 0)
					nums.value = 0;
				_song.notes[curSection].sectionSpeed = nums.value;
				updateGrid();
			}
			else if (wname == 'song_bpm')
			{
				if (nums.value <= 0)
					nums.value = 1;
				tempBpm = Std.int(nums.value);
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(Std.int(nums.value));
			}
			else if(wname == 'effect_Length')
			{	
				if(!prefab){
					if(curSelectedEffect != null){

						if (nums.value <= 0)
							nums.value = 0;
						curSelectedEffect.duration = nums.value / 2000;
						updateGrid();
					}
				}else{
					
					if(FlxG.save.data.effectPrefab[effectPrefabSelected] != null){

						if (nums.value <= 0)
							nums.value = 0;
						FlxG.save.data.effectPrefab[effectPrefabSelected].duration = nums.value / 2000;
						updateGrid();
					}

				}


			}
			else if(wname == 'effect_Quant')
			{	
				if(!prefab){
					if(curSelectedEffect != null){
						if(curSelectedEffect.target == 'alpha'){
							curSelectedEffect.quantity = nums.value/1000;
						}else{
							curSelectedEffect.quantity = nums.value;
						}
						updateGrid();
					}
				}else{
					
					if(FlxG.save.data.effectPrefab[effectPrefabSelected] != null){
						if(FlxG.save.data.effectPrefab[effectPrefabSelected].target == 'alpha'){
							FlxG.save.data.effectPrefab[effectPrefabSelected].quantity = nums.value/1000;
						}else{
							FlxG.save.data.effectPrefab[effectPrefabSelected].quantity = nums.value;
						}
						updateGrid();
					}


				}

			}
			else if (wname == 'note_susLength')
			{	
				if(!prefab){
					if (curSelectedNote != null){

						if (nums.value <= 0)
							nums.value = 0;
						curSelectedNote[2] = nums.value;
						updateGrid();
					}
				}else{
					
					if (FlxG.save.data.notePrefab[notePrefabSelected] != null){

						if (nums.value <= 0)
							nums.value = 0;
						FlxG.save.data.notePrefab[notePrefabSelected].hold = nums.value;
						updateGrid();
					}
				}
			}
			else if (wname == 'note_speed')
			{	
				if(!prefab){

					if (curSelectedNote != null){

						curSelectedNote[3] = nums.value;
					}
					updateGrid();
				}else{
					
					
					if (FlxG.save.data.notePrefab[notePrefabSelected] != null){

						FlxG.save.data.notePrefab[notePrefabSelected].speed = nums.value;
					}
					updateGrid();


				}	
			}
			else if (wname == 'note_type')
			{	

				if(!prefab){
					if (curSelectedNote != null){
		
						curSelectedNote[4] = nums.value;
					}
					updateGrid();
				}else{
					
					if (FlxG.save.data.notePrefab[notePrefabSelected] != null){
		
						FlxG.save.data.notePrefab[notePrefabSelected].type = nums.value;
					}
					updateGrid();

				}
			}
			else if (wname == 'section_bpm')
			{
				if (nums.value <= 0.1)
					nums.value = 0.1;
				_song.notes[curSection].bpm = Std.int(nums.value);
				updateGrid();
			}else if(wname == 'spawn_change'){

				_song.notes[curSection].spawn = nums.value;
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	/* this function got owned LOL
		function lengthBpmBullshit():Float
		{
			if (_song.notes[curSection].changeBPM)
				return _song.notes[curSection].lengthInSteps * (_song.notes[curSection].bpm / _song.bpm);
			else
				return _song.notes[curSection].lengthInSteps;
	}*/
	function sectionStartTime():Float
	{
		var daBPM:Int = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection)
		{
			if (_song.notes[i].changeBPM)
			{
				daBPM = _song.notes[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	var writingNotes:Bool = false;

	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();

		if(_song.notes[curSection].effects == null){

			_song.notes[curSection].effects = [];
			trace('effects not null anymore :)');
		}

		if (FlxG.keys.justPressed.ALT && UI_box.selected_tab == 0 && !prefab)
		{
			writingNotes = !writingNotes;
		}
		
		if (writingNotes)
			writingNotesText.text = "WRITING NOTES";
		else
			writingNotesText.text = "";
		

		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = typingShit.text;

		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;

		var controlArray:Array<Bool> = [leftP, downP, upP, rightP];

		if ((upP || rightP || downP || leftP) && writingNotes)
		{
			for(i in 0...controlArray.length)
			{
				if (controlArray[i])
				{
					for (n in 0..._song.notes[curSection].sectionNotes.length)
						{
							var note = _song.notes[curSection].sectionNotes[n];
							if (note == null)
								continue;
							if (note[0] == Conductor.songPosition && note[1] % 4 == i)
							{
								trace('GAMING');
								_song.notes[curSection].sectionNotes.remove(note);
							}
						}
					trace('adding note');
					_song.notes[curSection].sectionNotes.push([Conductor.songPosition, i, 0]);
					updateGrid();
				}
			}

		}

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps));

		if (curBeat % 4 == 0 && curStep >= 16 * (curSection + 1))
		{
			trace(curStep);
			trace((_song.notes[curSection].lengthInSteps) * (curSection + 1));
			trace('DUMBSHIT');

			if (_song.notes[curSection + 1] == null)
			{
				addSection();
			}

			changeSection(curSection + 1, false);
		}

		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (FlxG.mouse.justPressed && !prefab)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes) && ! effects.checked)
			{
				//make another car rendered for effects and so give rendered of effects sprites (probably of the strum line notes)

				curRenderedNotes.forEach(function(note:Note)
				{

					if (FlxG.keys.pressed.CONTROL)
					{
						if (FlxG.mouse.overlaps(note))
						{
							
							selectNote(note);
							

							//create a select effect
							

						}
					}else if(FlxG.mouse.overlaps(note)){
						
						deleteNote(note);
						
					}

				});


			}
			else
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps)
					&& ! effects.checked)
				{

					
					FlxG.log.add('added note');
					addNote();
					
				}

			}

			

			if (FlxG.mouse.overlaps(curRenderedEffects) && effects.checked)
			{
				//make another car rendered for effects and so give rendered of effects sprites (probably of the strum line notes)
		
				curRenderedEffects.forEach(function(effect:SpriteEffect)
				{
	
					if (FlxG.keys.pressed.CONTROL)
					{
						if (FlxG.mouse.overlaps(effect))
						{
							
							selectEffect(effect);
							
		
							//create a select effect
									
		
						}
					}else if(FlxG.mouse.overlaps(effect)){
							
							deleteEffect(effect);
		
							
					}
		
				});
		
		
			}else{

				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps)
					&& effects.checked)
				{
	
					FlxG.log.add('added effect');
					addEffect();
			
						
				}


			}
		}

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
		{
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			lastSection = curSection;
			
			PlayState.SONG = _song;
			FlxG.sound.music.stop();
			vocals.stop();
			FlxG.switchState(new PlayState());
		}

		if (FlxG.keys.justPressed.E)
		{	
			if(! effects.checked){
				if(curSelectedNote != null){ 
					if(curSelectedNote[0] < sectionStartTime() + (Conductor.stepCrochet) * (_song.notes[curSection].lengthInSteps - 1)){
						curSelectedNote[0] += Conductor.stepCrochet;
					}
				}
				updateGrid();
			}else{
				if(curSelectedEffect != null){ 
					
					if(curSelectedEffect.time < sectionStartTime() + (Conductor.stepCrochet) * (_song.notes[curSection].lengthInSteps - 1)){
						curSelectedEffect.time += Conductor.stepCrochet;
					}
				}
				updateGrid();

			}


		}
		if (FlxG.keys.justPressed.Q)
		{	

			if(! effects.checked){
				if(curSelectedNote != null){ 
					if(curSelectedNote[0] > sectionStartTime()){
						curSelectedNote[0] -= Conductor.stepCrochet;
					}
				}
				updateGrid();
			}else{
				
				if(curSelectedEffect != null){ 
					if(curSelectedEffect.time > sectionStartTime()){
						curSelectedEffect.time -= Conductor.stepCrochet;
					}
				}
				updateGrid();

			}

		}

		if (FlxG.keys.justPressed.TAB)
		{
			if (FlxG.keys.pressed.SHIFT)
			{
				UI_box.selected_tab -= 1;
				if (UI_box.selected_tab < 0)
					UI_box.selected_tab = 2;
			}
			else
			{
				UI_box.selected_tab += 1;
				if (UI_box.selected_tab >= 3)
					UI_box.selected_tab = 0;
			}
		}
		
		
		if (FlxG.keys.justPressed.P && UI_box.selected_tab == 0)
		{
			prefab = !prefab;

		writingNotes = false;

			if (FlxG.sound.music.playing)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if(prefab){
				tab_group_note.remove(effects);

				if(effects.checked){
					prefabNotesText.text = 'Effect ' + effectPrefabSelected;

					updateEffectUI();

				}else{
					prefabNotesText.text = 'Note ' + notePrefabSelected;

					updateNoteUI();

				}

			}else{
				tab_group_note.add(effects);
				prefabNotesText.text = '';

				FlxG.save.flush();

				updateNoteUI();
				updateEffectUI();
			}

				

		}

		
		

		if (!typingShit.hasFocus)
		{

			if (FlxG.keys.pressed.CONTROL && !effects.checked)
			{	
				



				if (FlxG.keys.justPressed.Z && lastNote != null)
				{
					trace(curRenderedNotes.members.contains(lastNote) ? "delete note" : "add note");
					if (curRenderedNotes.members.contains(lastNote))
						deleteNote(lastNote);
					else 
						addNote(lastNote);
				}
			}//add effects to the ctrl z thingy 

			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;
			if (!writingNotes && !prefab)
			{
				if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
					changeSection(curSection + shiftThing); 
				if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
					changeSection(curSection - shiftThing);

			}else if(prefab){

				if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D){

					if(effects.checked){

						if(effectPrefabSelected != 30){

							effectPrefabSelected++;
						}

						if(FlxG.save.data.effectPrefab[effectPrefabSelected] == null){

							FlxG.save.data.effectPrefab[effectPrefabSelected] = {
								quantity: 0,
								duration: 0,
								target: 'x',
								all: true,
								set: false,
								way: 'none'
							};

						}

						prefabNotesText.text = 'Effect ' + effectPrefabSelected;
						updateEffectUI();

					}else{

						if(notePrefabSelected != 30){

							notePrefabSelected++;

						}

						if(FlxG.save.data.notePrefab[notePrefabSelected] == null){

							FlxG.save.data.notePrefab[notePrefabSelected] = {

								hold: 0,
								speed: 1,
								type: 0
					
							};
				
						}

						
						prefabNotesText.text = 'Note ' + notePrefabSelected;
						updateNoteUI();

					}

				}
					
				if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A){

					if(effects.checked){

						if(effectPrefabSelected != 0){

							effectPrefabSelected--;
						}

						if(FlxG.save.data.effectPrefab[effectPrefabSelected] == null){

							FlxG.save.data.effectPrefab[effectPrefabSelected] = {
								quantity: 0,
								duration: 0,
								target: 'x',
								all: true,
								set: false,
								way: 'none'
							};

						}

						prefabNotesText.text = 'Effect ' + effectPrefabSelected;
						updateEffectUI();

					}else{

						if(notePrefabSelected != 0){

							notePrefabSelected--;

						}

						if(FlxG.save.data.notePrefab[notePrefabSelected] == null){

							FlxG.save.data.notePrefab[notePrefabSelected] = {

								hold: 0,
								speed: 1,
								type: 0
					
							};
				
						}

						prefabNotesText.text = 'Note ' + notePrefabSelected;
						updateNoteUI();

						
					}

					FlxG.save.data.prefabNote = notePrefabSelected;

		
					FlxG.save.data.prefabEffect = effectPrefabSelected;

				}
					

			}	


			if (FlxG.keys.justPressed.SPACE)
			{
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					vocals.pause();
				}
				else
				{
					vocals.play();
					FlxG.sound.music.play();
				}
			}

			if (FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.music.pause();
				vocals.pause();

				FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4);
				vocals.time = FlxG.sound.music.time;
			}

			if (!FlxG.keys.pressed.SHIFT)
			{
				if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();

					var daTime:Float = 700 * FlxG.elapsed;

					if (FlxG.keys.pressed.W)
					{
						FlxG.sound.music.time -= daTime;
					}
					else
						FlxG.sound.music.time += daTime;

					vocals.time = FlxG.sound.music.time;
				}
			}
			else
			{
				if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();

					var daTime:Float = Conductor.stepCrochet * 2;

					if (FlxG.keys.justPressed.W)
					{
						FlxG.sound.music.time -= daTime;
					}
					else
						FlxG.sound.music.time += daTime;

					vocals.time = FlxG.sound.music.time;
				}
			}
		}

		_song.bpm = tempBpm;

		/* if (FlxG.keys.justPressed.UP)
				Conductor.changeBPM(Conductor.bpm + 1);
			if (FlxG.keys.justPressed.DOWN)
				Conductor.changeBPM(Conductor.bpm - 1); */

		bpmTxt.text = bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))
			+ "\nSection: "
			+ curSection 
			+ "\nCurStep: " 
			+ curStep;
		super.update(elapsed);
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		
		updateGrid();
		

		FlxG.sound.music.pause();
		vocals.pause();

		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		vocals.time = FlxG.sound.music.time;
		updateCurStep();

		updateGrid();
		updateSectionUI();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		trace('changing section' + sec);

		

		if (_song.notes[sec] != null)
		{
			trace('naw im not null');
			curSection = sec;
			updateGrid();

			if (updateMusic)
			{
				FlxG.sound.music.pause();
				vocals.pause();

				/*var daNum:Int = 0;
					var daLength:Float = 0;
					while (daNum <= sec)
					{
						daLength += lengthBpmBullshit();
						daNum++;
				}*/

				FlxG.sound.music.time = sectionStartTime();
				vocals.time = FlxG.sound.music.time;
				updateCurStep();
			}

			if(_song.notes[sec].effects == null){

				_song.notes[sec].effects = [];
				trace('i was null now im not YEY!');
			}
			
			updateGrid();
			updateSectionUI();
			updateHeads();
		}else{
			
			trace('bro wtf I AM NULL');
	
		}

		
	}

	function copySection(?sectionNum:Int = 1)
	{
		var daSec = FlxMath.maxInt(curSection, sectionNum);

		if(! effects.checked){

			for (note in _song.notes[daSec - sectionNum].sectionNotes)
			{
				var strum = note[0] + Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * sectionNum);

				var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3], note[4]];
				_song.notes[daSec].sectionNotes.push(copiedNote);
			}

		}else{

			for(effect in _song.notes[daSec - sectionNum].effects){

				var strum = effect.time + Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * sectionNum);

				var copiedEffect:EffectParams = {
					time: strum,
					quantity: effect.quantity,
					duration: effect.duration,
					target: effect.target,
					targetInt: effect.targetInt,
					way: effect.way,
					player: effect.player,
					set: effect.set,
					all: effect.all

				};
				
				_song.notes[daSec].effects.push(copiedEffect);


			}


		}

		updateGrid();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSection];

		stepperLength.value = sec.lengthInSteps;


		check_mustHitSection.checked = sec.mustHitSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;
		
		if(Std.isOfType(sec.spawn, Float)){
			stepperSpawn.value = sec.spawn;
		}else{
			stepperSpawn.value = 2000;
		}

		if(Std.isOfType(sec.sectionSpeed, Float)){
			stepperSecSpeed.value = sec.sectionSpeed;
		}else{
			stepperSecSpeed.value = 1;
		}

		 

		updateHeads();
	}

	function updateHeads():Void
	{

		
			if ( (lockPos.checked || effects.checked) && Swap.checked)
			{
				leftIcon.animation.play(_song.player1);
				rightIcon.animation.play(_song.player2);
				
			}
			else
			{
				if((lockPos.checked || effects.checked) && ! Swap.checked){

					leftIcon.animation.play(_song.player2);
					rightIcon.animation.play(_song.player1);

				}else{
					if(check_mustHitSection.checked){
	
						leftIcon.animation.play(_song.player1);
						rightIcon.animation.play(_song.player2);
	
					}else{
						
						leftIcon.animation.play(_song.player2);
						rightIcon.animation.play(_song.player1);
	
					}
				}
				
			}
		

	}

	function updateNoteUI():Void
	{	

		if(!prefab){
			if (curSelectedNote != null){
				stepperSusLength.value = curSelectedNote[2];

				if(curSelectedNote[3] != null){
					stepperSpeed.value = curSelectedNote[3];
				}else{
					stepperSpeed.value = 1;

				}

				if(curSelectedNote[4] != null){
					stepperType.value = curSelectedNote[4];

				}else{
					stepperType.value = 0;

				}

			}
		}else{

			if (FlxG.save.data.notePrefab[notePrefabSelected] != null){

					stepperSusLength.value = FlxG.save.data.notePrefab[notePrefabSelected].hold;
					stepperSpeed.value = FlxG.save.data.notePrefab[notePrefabSelected].speed;
					stepperType.value = FlxG.save.data.notePrefab[notePrefabSelected].type;


			}

		}
	}

	function updateEffectUI():Void
	{	

		if(!prefab){
			if (curSelectedEffect != null){

				effectLength.value = curSelectedEffect.duration;

				effectLength.value *= 2000;

				effectQuant.value = curSelectedEffect.quantity;

				if(curSelectedEffect.target == 'alpha'){
					effectQuant.value *= 1000;
				}

				modifierType.header.text.text = curSelectedEffect.target;

				adding.checked = curSelectedEffect.all;

				setting.checked = curSelectedEffect.set;

				trace(curSelectedEffect.way);

				if(curSelectedEffect.way == 'none'){

					easeDirection.header.text.text = 'Out';

					easeTypeDropDown.header.text.text = 'none';

				}


				if(curSelectedEffect.way.endsWith('In')){

					easeDirection.header.text.text = 'In';

					var split:Array<String> = curSelectedEffect.way.split('In');

					easeTypeDropDown.header.text.text = split[0];

				}

				
				if(curSelectedEffect.way.endsWith('Out')){

					

					easeDirection.header.text.text = 'Out';

					var split:Array<String> = curSelectedEffect.way.split('Out');

					easeTypeDropDown.header.text.text = split[0];

				}

				
				if(curSelectedEffect.way.endsWith('InOut')){

					easeDirection.header.text.text = 'InOut';

					var split:Array<String> = curSelectedEffect.way.split('InOut');

					easeTypeDropDown.header.text.text = split[0];

				}



				
			}

		}else{
			
			if(FlxG.save.data.effectPrefab[effectPrefabSelected] != null){

				
				effectLength.value = FlxG.save.data.effectPrefab[effectPrefabSelected].duration;

				effectLength.value *= 2000;
				
				effectQuant.value = FlxG.save.data.effectPrefab[effectPrefabSelected].quantity;

				if(FlxG.save.data.effectPrefab[effectPrefabSelected].target == 'alpha'){
					effectQuant.value *= 1000;
				}
				
				modifierType.header.text.text = FlxG.save.data.effectPrefab[effectPrefabSelected].target;
				
				adding.checked = FlxG.save.data.effectPrefab[effectPrefabSelected].all;
				
				setting.checked = FlxG.save.data.effectPrefab[effectPrefabSelected].set;

				var way:String = FlxG.save.data.effectPrefab[effectPrefabSelected].way;

				if(way == 'none'){

					easeDirection.header.text.text = 'Out';

					easeTypeDropDown.header.text.text = 'none';

				}

				



				if(way.endsWith('In')){

					easeDirection.header.text.text = 'In';

					var split:Array<String> = way.split('In');

					easeTypeDropDown.header.text.text = split[0];

				}

				
				if(way.endsWith('Out')){

					

					easeDirection.header.text.text = 'Out';

					var split:Array<String> = way.split('Out');

					easeTypeDropDown.header.text.text = split[0];

				}

				
				if(way.endsWith('InOut')){

					easeDirection.header.text.text = 'InOut';

					var split:Array<String> = way.split('InOut');

					easeTypeDropDown.header.text.text = split[0];

				}
				trace('here finish');
			}
		}
	}


	function updateGrid():Void
	{
		remove(gridBG);
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * _song.notes[curSection].lengthInSteps);
        add(gridBG);

		remove(gridBlackLine);
		gridBlackLine = new FlxSprite(gridBG.x + gridBG.width / 2).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		add(gridBlackLine);
		
			while (curRenderedNotes.members.length > 0)
			{
				curRenderedNotes.remove(curRenderedNotes.members[0], true);
				

			}
		

		while (curRenderedSustains.members.length > 0)
		{
			curRenderedSustains.remove(curRenderedSustains.members[0], true);
		}

		while(curRenderedEffects.members.length > 0)
		{

			curRenderedEffects.remove(curRenderedEffects.members[0], true);

		}


		/*if(lockPos.checked && check_mustHitSection.checked){
			
			curRenderedSustains.members[0].centerOffsets();
			
		}*/

		

		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
		}
		else
		{
			// get last bpm
			var daBPM:Int = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}

		/* // PORT BULLSHIT, INCASE THERE'S NO SUSTAIN DATA FOR A NOTE
			for (sec in 0..._song.notes.length)
			{
				for (notesse in 0..._song.notes[sec].sectionNotes.length)
				{
					if (_song.notes[sec].sectionNotes[notesse][2] == null)
					{
						trace('SUS NULL');
						_song.notes[sec].sectionNotes[notesse][2] = 0;
					}
				}
			}
		 */

		if(! effects.checked){
			var sectionInfo:Array<Dynamic> = _song.notes[curSection].sectionNotes;
			for (i in sectionInfo)
			{
				var daNoteInfo = i[1];
				var daStrumTime = i[0];
				var daSus = i[2];
				var daSpeed = i[3];
				var daType = i[4];


				var note:Note = new Note(daStrumTime, daNoteInfo % 4, daSpeed, daType);
				note.sustainLength = daSus;
				note.setGraphicSize(GRID_SIZE, GRID_SIZE);
				note.updateHitbox();
				note.x = Math.floor(daNoteInfo  * GRID_SIZE);
				note.y = Math.floor( getYfromStrum(  (daStrumTime - sectionStartTime() )   % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps)) );
				if(daNoteInfo >= 4){
					note.player = true;
				}
				



				if (curSelectedNote != null)
					if (curSelectedNote[0] == note.strumTime)
						lastNote = note;

				if(lockPos != null){
					if(lockPos.checked){ 
						if(! Swap.checked){
							if(_song.notes[curSection].mustHitSection){

								if(note.x >= GRID_SIZE*4){
									note.x -= GRID_SIZE*4;
								}else{
									note.x += GRID_SIZE*4;
								}
								

							}
						}else{
							if(! _song.notes[curSection].mustHitSection){

								if(note.x >= GRID_SIZE*4){
									note.x -= GRID_SIZE*4;
								}else{
									note.x += GRID_SIZE*4;
								}
								

							}

						}
					}
				}
				
				curRenderedNotes.add(note);

				if (daSus > 0)
				{
					var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE / 2),
					note.y + GRID_SIZE).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * _song.notes[curSection].lengthInSteps, 0, gridBG.height)));

					curRenderedSustains.add(sustainVis);
				}
			}
		}else{

			

			if(_song.notes[curSection].effects != null){
				var sectionInfo:Array<EffectParams> = _song.notes[curSection].effects;
				for (i in sectionInfo)
				{
					var daNoteInfo = i.targetInt;
					var daStrumTime = i.time;
					var player = i.player;
					var daSus = i.duration * 1000;
					var anim = i.target;

					var effect:SpriteEffect = new SpriteEffect(daStrumTime, daNoteInfo % 4, player, anim);
					effect.setGraphicSize(GRID_SIZE, GRID_SIZE);
					effect.updateHitbox();
					if(i.player){
						daNoteInfo += 4;

					}

					effect.x = Math.floor(daNoteInfo  * GRID_SIZE);
					effect.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps)));

					

				
						
						if(Swap.checked){
							

							if(effect.x >= GRID_SIZE*4){
								effect.x -= GRID_SIZE*4;
							}else{
								effect.x += GRID_SIZE*4;
							}
									

							
						}
						
					
					
					curRenderedEffects.add(effect);

					if (daSus > 5)
					{
						var sustainVis:FlxSprite = new FlxSprite(effect.x + (GRID_SIZE / 2),
						effect.y + GRID_SIZE).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * _song.notes[curSection].lengthInSteps, 0, gridBG.height)));

						curRenderedSustains.add(sustainVis);
					}

					//trace(_song.notes[curSection].effects);

				}



			}
		}


	}

	private function addSection(lengthInSteps:Int = 16):Void
	{
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false,
			spawn: 2000,
			effects: [],
			sectionSpeed: 1
		};

		_song.notes.push(sec);
	}

	

	function selectNote(note:Note):Void
	{
		var swagNum:Int = 0;

		for (i in _song.notes[curSection].sectionNotes)
		{
			if (i[0] == note.strumTime && i[1] % 4 == note.noteData && (i[1] >= 4 ? true : false) == note.player)
			{
				curSelectedNote = _song.notes[curSection].sectionNotes[swagNum];
				trace('selected note: ', curSelectedNote);

				if(i[3] == null){
					i[3] =  1;
				}
			}

			swagNum += 1;
		}

		

		updateGrid();
		updateNoteUI();
	}

	function selectEffect(effect:SpriteEffect):Void
	{
		var swagNum:Int = 0;
	
		for (i in _song.notes[curSection].effects)
		{
			if (i.time == effect.time && i.targetInt == effect.targetInt && i.player == effect.player)
			{
				curSelectedEffect = _song.notes[curSection].effects[swagNum];
				trace('selected note: ', curSelectedNote);
			}
	
			swagNum += 1;
		}
	
		updateGrid();
		updateEffectUI();
	}





	function deleteNote(note:Note):Void
		{
			lastNote = note;
			
			for (i in _song.notes[curSection].sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] % 4 == note.noteData && (i[1] >= 4 ? true : false) == note.player)
				{	
					
					_song.notes[curSection].sectionNotes.remove(i);
				}

			}
	
			updateGrid();
		}

	function deleteEffect(effect:SpriteEffect){

			for (i in _song.notes[curSection].effects)
			{

				if (i.time == effect.time && i.targetInt == effect.targetInt && i.player == effect.player)
				{
					_song.notes[curSection].effects.remove(i);
				}
			}
	
			updateGrid();

	}

	function clearSection():Void
	{	
		if(! effects.checked){
			_song.notes[curSection].sectionNotes = [];
		}else{
			_song.notes[curSection].effects = [];

		}

		updateGrid();
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
			_song.notes[daSection].effects = [];
		}

		updateGrid();
	}

	function easeUpdate(useless:String):Void{

		if(!prefab){
			if(curSelectedEffect != null){
				
					curSelectedEffect.way = easeTypeDropDown.header.text.text + easeDirection.header.text.text;
					updateGrid();
				

			}
		}else{
			
			if(FlxG.save.data.effectPrefab[effectPrefabSelected] != null){
				
				FlxG.save.data.effectPrefab[effectPrefabSelected].way = easeTypeDropDown.header.text.text + easeDirection.header.text.text;
				updateGrid();
			

		}

		}

	}

	function targetUpdate(useless:String):Void{

		if(!prefab){
			if(curSelectedEffect != null){

				curSelectedEffect.target = modifierType.header.text.text;
				updateGrid();

			}
		}else{
			if(FlxG.save.data.effectPrefab[effectPrefabSelected] != null){

				FlxG.save.data.effectPrefab[effectPrefabSelected].target = modifierType.header.text.text;
				updateGrid();

			}

		}

	}


	private function addNote(?n:Note):Void
	{

		
			var noteStrum = getStrumTime(dummyArrow.y) + sectionStartTime();
			var noteData = Math.floor(FlxG.mouse.x / GRID_SIZE);
			var noteSus = FlxG.save.data.notePrefab[notePrefabSelected].hold;
			var noteSpeed = FlxG.save.data.notePrefab[notePrefabSelected].speed;
			var noteType = FlxG.save.data.notePrefab[notePrefabSelected].type;
			
			

			if(lockPos != null){
				if(lockPos.checked){

					if(! Swap.checked){

						if(_song.notes[curSection].mustHitSection){

							if(noteData > 3){
								noteData -= 4;
							}else{
								noteData += 4;
							}
							

						}
					}else{
						if(! _song.notes[curSection].mustHitSection){

							if(noteData > 3){
								noteData -= 4;
							}else{
								noteData += 4;
							}
							

						}

					}

				}
			}

			

			if (n != null)
				_song.notes[curSection].sectionNotes.push([n.strumTime, n.noteData, n.sustainLength, n.noteSpeed, n.noteType]);
			else
				_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus, noteSpeed, noteType]);

			var thingy = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1]; //I like the name of this variable -Ghost

			curSelectedNote = thingy;

			updateGrid();
			updateNoteUI();
		

			

		autosaveSong();
	}

	private function addEffect(? n:EffectParams){

		var newEffect:EffectParams = {

			time: getStrumTime(dummyArrow.y) + sectionStartTime(), 
			quantity: FlxG.save.data.effectPrefab[effectPrefabSelected].quantity, 
			duration: FlxG.save.data.effectPrefab[effectPrefabSelected].duration, 
			target: FlxG.save.data.effectPrefab[effectPrefabSelected].target,
			targetInt: Math.floor(FlxG.mouse.x / GRID_SIZE),
			way: FlxG.save.data.effectPrefab[effectPrefabSelected].way,
			player: Swap.checked,
			set: FlxG.save.data.effectPrefab[effectPrefabSelected].set,
			all: FlxG.save.data.effectPrefab[effectPrefabSelected].all


		};
			//trace(newEffect.targetInt, newEffect.player);
			if(newEffect.targetInt >= 4){
				newEffect.targetInt -= 4;
				newEffect.player = ! newEffect.player;
				//trace(newEffect.targetInt);
			}

			if (n != null)
				_song.notes[curSection].effects.push(n);
			else
				_song.notes[curSection].effects.push(newEffect);

			var thingy0 = _song.notes[curSection].effects[_song.notes[curSection].effects.length - 1]; //I copied the name of this variable -Ghost

			curSelectedEffect = thingy0;

			updateGrid();
			updateEffectUI();
			autosaveSong();

		



	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime,  0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height);
	}

	/*
		function calculateSectionLengths(?sec:SwagSection):Int
		{
			var daLength:Int = 0;

			for (i in _song.notes)
			{
				var swagLength = i.lengthInSteps;

				if (i.typeOfSection == Section.COPYCAT)
					swagLength * 2;

				daLength += swagLength;

				if (sec != null && sec == i)
				{
					trace('swag loop??');
					break;
				}
			}

			return daLength;
	}*/
	private var daSpacing:Float = 0.3;

	function loadLevel():Void
	{
		trace(_song.notes);
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}
 
		return noteData;
	}

	function loadJson(song:String):Void
	{
		PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
		FlxG.resetState();
	}

	function loadAutosave():Void
	{
		PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
		FlxG.resetState();
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	private function saveLevel()
	{
		var json = {
			"song": _song
		};
 
		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + ".json");
		}
	}
 
	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}



}
