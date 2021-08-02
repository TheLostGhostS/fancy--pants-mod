package;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.input.FlxKeyManager;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

using StringTools;

class DialogueBox extends FlxSpriteGroup
{
	var box:FlxSprite;

	var curCharacter:String = '';

	var dialogue:Alphabet;
	var dialogueList:Array<String> = [];

	// SECOND DIALOGUE FOR THE PIXEL SHIT INSTEAD???
	var swagDialogue:FlxTypeText;

	var dropText:FlxText;

	public var finishThing:Void->Void;

	var portraitLeft:FlxSprite;
	var portraitRight:FlxSprite;

	

	var handSelect:FlxSprite;
	var bg:FlxSprite;

	var n:Int = 0;

	var flip:Bool = false;

	public function new(talkingRight:Bool = true, ?dialogueList:Array<String>)
	{
		super();

		bg = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFB3DFd8);
		bg.scrollFactor.set();
		bg.alpha = .7;
		add(bg);



		box = new FlxSprite(-20, 45);

		
		
		var hasDialog = false;
		
		hasDialog = true;
		box.frames = Paths.getSparrowAtlas('speech_bubble_talking', 'shared');
		box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
		box.animation.addByIndices('normal', 'speech bubble normal', [4], "", 24);

		
		

		this.dialogueList = dialogueList;
		
		if (!hasDialog)
			return;
		
		
		portraitLeft = new FlxSprite(100, 200).loadGraphic(Paths.image('fptalk'));
		
		portraitLeft.setGraphicSize(Std.int(portraitLeft.width * 0.3));
		portraitLeft.updateHitbox();
		portraitLeft.scrollFactor.set();
		add(portraitLeft);
		portraitLeft.visible = false;

		portraitRight = new FlxSprite(720, 310).loadGraphic(Paths.image('bftalk'));

		portraitRight.setGraphicSize(Std.int(portraitRight.width * 0.3));
		portraitRight.updateHitbox();
		portraitRight.scrollFactor.set();
		add(portraitRight);
		portraitRight.visible = false;
		
		
		box.animation.play('normalOpen');
		box.setGraphicSize(Std.int(box.width * 0.15 * PlayState.daPixelZoom), Std.int(box.height * 0.4));
		box.y = 520;
		box.updateHitbox();
		add(box);

		box.screenCenter(X);


		if (!talkingRight)
		{
			// box.flipX = true;
		}

		dropText = new FlxText(202, 602, 1430, "", 32);
		dropText.font = 'Pixel Arial 11 Bold';
		dropText.color = 0xFF666666;
		dropText.scale.set(dropText.scale.x * .6, dropText.scale.y * .6);
		dropText.updateHitbox();
		add(dropText);

		swagDialogue = new FlxTypeText(200, 600, 1430, "", 32);
		swagDialogue.font = 'Pixel Arial 11 Bold';
		swagDialogue.color = 0xFF000000;
		swagDialogue.sounds = [FlxG.sound.load(Paths.sound('pixelText'), 0.6)];
		swagDialogue.scale.set(swagDialogue.scale.x * .6, swagDialogue.scale.y * .6);
		swagDialogue.updateHitbox();
		add(swagDialogue);

		dialogue = new Alphabet(0, 80, "", false, true);
		// dialogue.x = 90;
		// add(dialogue);

		
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;

	override function update(elapsed:Float)
	{
		// HARD CODING CUZ IM STUPDI
		if (PlayState.SONG.song.toLowerCase() == 'roses')
			portraitLeft.visible = false;
		if (PlayState.SONG.song.toLowerCase() == 'thorns')
		{
			portraitLeft.color = FlxColor.BLACK;
			swagDialogue.color = FlxColor.WHITE;
			dropText.color = FlxColor.BLACK;
		}

		dropText.text = swagDialogue.text;

		

		if (box.animation.curAnim != null)
		{
			if (box.animation.curAnim.name == 'normalOpen' && box.animation.curAnim.finished)
			{
				box.animation.play('normal');
				dialogueOpened = true;
			}
		}

		if (dialogueOpened && !dialogueStarted)
		{
			startDialogue();
			dialogueStarted = true;
		}

		if (FlxG.keys.justPressed.ANY  && dialogueStarted == true)
		{
			remove(dialogue);
				
			FlxG.sound.play(Paths.sound('clickText'), 0.8);

			if (dialogueList[1] == null && dialogueList[0] != null)
			{	

				
				if (!isEnding)
				{	

					portraitLeft.visible = false;
					portraitRight.visible = false;

					isEnding = true;

					
					FlxTween.tween(box, {alpha: 0}, 1.2, {ease: FlxEase.linear} );
					FlxTween.tween(bg, {alpha: 0}, 1.2, {ease: FlxEase.linear}  );
					FlxTween.tween(swagDialogue, {alpha: 0}, 1.2, {ease: FlxEase.linear} );
					FlxTween.tween(dropText, {alpha: 0}, 1.2, {ease: FlxEase.linear} );
					
					
					

					new FlxTimer().start(1.2, function(tmr:FlxTimer)
					{
						finishThing();
						kill();
					});
				}
			}
			else
			{
				dialogueList.remove(dialogueList[0]);
				startDialogue();
			}
		}
		
		super.update(elapsed);
	}

	var isEnding:Bool = false;

	function startDialogue():Void
	{
		cleanDialog();
		// var theDialog:Alphabet = new Alphabet(0, 70, dialogueList[0], false, true);
		// dialogue = theDialog;
		// add(theDialog);

		// swagDialogue.text = ;
		swagDialogue.resetText(dialogueList[0]);
		swagDialogue.start(0.04, true);

		//trace(curCharacter);

		switch (curCharacter)
		{
			case 'dad':

				dropText.color = 0xFFB3B3B3;
				portraitRight.visible = false;

				FlxTween.completeTweensOf(portraitRight);
				FlxTween.completeTweensOf(portraitLeft);

				if (!portraitLeft.visible)
				{	
					
					portraitLeft.visible = true;
					portraitLeft.x -= 50;
					portraitLeft.alpha = 0;
					FlxTween.tween(portraitLeft, {x: portraitLeft.x + 50, alpha: 1}, .5);
				//	portraitLeft.animation.play('enter');
				}

				box.flipX = true;
			case 'bf':
				portraitLeft.visible = false;

				FlxTween.completeTweensOf(portraitRight);
				FlxTween.completeTweensOf(portraitLeft);

				if (!portraitRight.visible)
				{	

					portraitRight.visible = true;
					portraitRight.x += 50;
					portraitRight.alpha = 0;
					FlxTween.tween(portraitRight, {x: portraitRight.x - 50, alpha: 1}, .5);
				//	portraitRight.animation.play('enter');
				}
				dropText.color = 0xFF00B2D3;
			
				box.flipX = false;
			


		}
	}

	function cleanDialog():Void
	{	
		if(dialogueList[0] != null){
			var splitName:Array<String> = dialogueList[0].split(":");
			curCharacter = splitName[1];
			dialogueList[0] = dialogueList[0].substr(splitName[1].length + 2).trim();
		}
	}
}
