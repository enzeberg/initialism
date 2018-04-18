package
{
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.events.Event;
	import flash.ui.Mouse;
	import flash.events.MouseEvent;
    import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextFieldAutoSize;
	import flash.utils.setTimeout;
	import flash.events.KeyboardEvent;

	public class Initialism extends MovieClip
	{
		private var card:Card;
		private var mouse:NewMouse;
		private var letterTF:TextField;
		private var remindTF:TextField;
		private var explainTF:TextField;
		private var scoreTF:TextField;
		private var cards:Array;
		private var clickedCards:Vector.<Card>;
		private var suppliedCards:Vector.<Card>;
		private var wordAry:Array;
		private var loader:URLLoader;
		private var myRequest:URLRequest;
		private var resultXML:XML;
		private var recordW:uint;
		private var score:uint=0;
	    private static const spacing:uint=38;
		private static const offsetX:uint=30;
		private static const offsetY:uint=40;
		public function startInitialism()
		{
			clickedCards=new Vector.<Card>();
			
			explainTF=new TextField();//explainTF和scoreTF实例化一次就行了，而remindTF需要经常被重新实例化。
			scoreTF=new TextField();
			stopOKBtn();
			buildCards();
			loadXML();
			refreshBtn.addEventListener(MouseEvent.CLICK,refreshCards);//当玩家在最后两行难以找到自己所知道
//的缩略词时，可以单击refreshBtn按钮，来更换所有卡片。但必须限制玩家不能在选中卡片时单击refreshBtn按钮
//，否则会出现很多问题。按照逻辑，玩家确实不应该在选中卡片时单击该按钮（因为这时玩家会面对两种情况，一，玩家
//想要点击okBtn；二，玩家想要放弃，便再次单击选中的卡片以取消选中）。尽管这样，仍有必要
//添加该限制，避免玩家在这时不小心点击了refreshBtn，或是故意“玩弄”你的程序。添加该限制的代码也不复杂
//，在玩家选中了卡片后“冰冻”该按钮，在玩家取消选中后或是点击okBtn(无论匹配成功与否）后，将该按钮激活。
            refreshBtn.addEventListener(MouseEvent.MOUSE_OVER,remindTheBtnMeans);
			refreshBtn.addEventListener(MouseEvent.MOUSE_OUT,removeTheBtnMeans);
			
			aboutSearchFunction();//这是跟搜索功能有关的函数
			//personalMouse();               
		}
		//--------------------------------refreshBtn按钮的三个事件侦听器--------
		private function refreshCards(e:MouseEvent):void{
			for(var c in cards){
				for(var k:uint=0;k<8;k++){
					if(stage.contains(cards[c][k])){
						removeChild(cards[c][k]);
					}
				}
			}
			buildCards();
		}
		private function remindTheBtnMeans(e:MouseEvent):void{
			reminder("刷新卡片板块");
		}
		private function removeTheBtnMeans(e:MouseEvent):void{
			if(stage.contains(remindTF)){
				removeChild(remindTF);
			}
		}
		//-----------------------------------------------------------------------
		//SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS  搜索功能  SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
		private function aboutSearchFunction():void{
			stopSearchBtn();//初始状态，“冰冻”searchBtn。
			searchTF.addEventListener(Event.CHANGE,textIsChanged);
			searchBtn.addEventListener(MouseEvent.CLICK,clickSearchBtn);
		}
		private function textIsChanged(e:Event):void{
			searchTF.text=searchTF.text.toUpperCase();
			if(searchTF.length>1){
				activateSearchBtn();
				stage.addEventListener(KeyboardEvent.KEY_DOWN,enterKeyDown);//让Enter键也能代替searchBtn的作用。
			}else{
				stopSearchBtn();
			}
		}
		private function enterKeyDown(e:KeyboardEvent):void{
			if(e.keyCode==13){
				search();
				stopSearchBtn();//在敲击了回车键后，要将searchBtn“冰冻”
			}
		}
		private function clickSearchBtn(e:MouseEvent):void{
			search();
			stopSearchBtn();//单击了searchBtn之后，也要将其“冰冻”
		}
		private function search():void{
			var wordInputed:String=searchTF.text;
			searchTF.text="";
			for(var w in wordAry){
				if(wordInputed==wordAry[w]){
					
					explainer(String(resultXML.words.word[w].@enExplain+"      "+resultXML.words.word[w].@cnExplain));
					break;
				}else{
					if(w==wordAry.length-1){
						reminder("抱歉，未搜索到您输入的内容");
						addEventListener(Event.ENTER_FRAME,removeRemindTF);
					}
				}
			}
		}
		private function removeRemindTF(e:Event):void{
			if(stage.contains(remindTF)){
				remindTF.alpha-=0.02;
				if(remindTF.alpha<=0){
					removeChild(remindTF);//在视觉效果上，该行可以不写。但为了避免舞台上添加了过多的remindTF
		           //（有些是曾经是remindTF，因为remindTF这一变量只持有最后一个文本框的引用）
					
					removeEventListener(Event.ENTER_FRAME,removeRemindTF);
				}
			}
			
		}
		private function activateSearchBtn():void{
			searchBtn.alpha=1;
		    searchBtn.mouseEnabled=true;
		}
		private function stopSearchBtn():void{
			searchBtn.alpha=0.2;
			searchBtn.mouseEnabled=false;
		}
		//SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
		private function buildCards():void{
			cards=new Array();
			for(var col:uint=0;col<7;col++){
				cards.push(new Array());
				cards[col].choosedTimes=0;
				for(var row:uint=0;row<8;row++){
					card =new Card();
					card.x=col*spacing+offsetX;
			        card.y=row*spacing+offsetY;
		            addChild(card);
					dispatchLetter();
					card.col=col;
					card.ro=row;
					card.letter=letterTF.text;
					card.addChild(letterTF);
					if((row==7)||(row==6)){
						addEventListenerFor(card);
					}
					cards[col][row]=card;
				}
			}
		}
		private function dispatchLetter():void{
			letterTF=new TextField();
			letterTF.width=36;
			letterTF.height=36;
			letterTF.defaultTextFormat=new TextFormat("Verdana",30,0xffffff*Math.random());
			letterTF.selectable=false;
			letterTF.text=String.fromCharCode((Math.floor(Math.random()*26)+1)+64);//可得到65~90（分别对应A和Z）的随机数。
		    letterTF.x=-19;
			letterTF.y=1;
		}
		private function addEventListenerFor(c:Card):void{
			c.addEventListener(MouseEvent.MOUSE_OVER,mouse_over);
			c.addEventListener(MouseEvent.MOUSE_OUT,mouse_out);
			c.addEventListener(MouseEvent.CLICK,chooseCard);
		}
		private function mouse_over(e:MouseEvent):void{
			e.currentTarget.alpha=0.7;
		}
		private function mouse_out(e:MouseEvent):void{
			e.currentTarget.alpha=1;
		}
		private function chooseCard(e:MouseEvent):void{
			e.currentTarget.removeEventListener(MouseEvent.MOUSE_OVER,mouse_over);
			e.currentTarget.removeEventListener(MouseEvent.MOUSE_OUT,mouse_out);
			e.currentTarget.removeEventListener(MouseEvent.CLICK,chooseCard);
			var clickedCard:Card=(e.currentTarget as Card);
			cards[clickedCard.col].choosedTimes++;//某一列的卡片被单击了，就让cards[该列]的choosedTimes属性加一。
			clickedCard.alpha=.3;
			clickedCards.push(clickedCard);
            wordTF.appendText(clickedCard.letter);
			clickAgain();
			activateOKBtn();
			stopRefreshBtn();
		}
		private function clickAgain():void{
			for(var k in clickedCards){
				var lie:uint=clickedCards[k].col;
				var hang:uint=clickedCards[k].ro;
				cards[lie][hang].addEventListener(MouseEvent.MOUSE_OVER,remind);//就是让鼠标悬停在已单击过卡片上时提示玩家再次单击就会“取消选中”
				cards[lie][hang].addEventListener(MouseEvent.MOUSE_OUT,quitReminding);//鼠标离开时取消提示
				cards[lie][hang].addEventListener(MouseEvent.CLICK,quitChoosing);
			}
		}
		private function remind(e:MouseEvent):void{
			reminder("再次单击将取消选中");
		}
		private function reminder(txt:String):void{
			remindTF=new TextField();
			remindTF.defaultTextFormat=new TextFormat("Verdana",35,0x00ccdd);
			remindTF.autoSize="left";
			//remindTF.wordWrap=true;
			remindTF.width=200;
			remindTF.text=txt;
			remindTF.x=(stage.stageWidth-remindTF.width)/2;
			remindTF.y=(stage.stageHeight-remindTF.height)/2;
			addChild(remindTF);
		}
		private function quitReminding(e:MouseEvent):void{
			if((remindTF!=null)&&(stage.contains(remindTF))){
				removeChild(remindTF);
			}
		}
		private function quitChoosing(e:MouseEvent):void{
			for(var k in clickedCards){
				var lie:uint=clickedCards[k].col;
				var hang:uint=clickedCards[k].ro;
				cards[lie].choosedTimes--;//当然也可以直接让它设为0，但那样会有重复设定的情况。感觉这样做更好一点。
				cards[lie][hang].alpha=1;
				cards[lie][hang].removeEventListener(MouseEvent.CLICK,quitChoosing);
				cards[lie][hang].removeEventListener(MouseEvent.MOUSE_OVER,remind);
				cards[lie][hang].addEventListener(MouseEvent.MOUSE_OVER,mouse_over);
				cards[lie][hang].addEventListener(MouseEvent.MOUSE_OUT,mouse_out);
				cards[lie][hang].addEventListener(MouseEvent.CLICK,chooseCard);
			}
			stopOKBtn();
			activateRefreshBtn();
			clickedCards.length=0;
			wordTF.text="";

		}
		private function loadXML():void{
			loader=new URLLoader();
			myRequest=new URLRequest("initialism.xml");//URLRequest()函数的参数必须为字符串格式。
			try{
				loader.load(myRequest);
			}
			catch(err:Error){
				trace("Unable to load URL: "+myRequest);
			}
			loader.addEventListener(Event.COMPLETE,finishLoading);
		}
		private function finishLoading(e:Event):void{
			resultXML=new XML(e.target.data);
			wordAry=new Array();
			for(var k in resultXML.words.word){
				wordAry.push(resultXML.words.word[k]);
			}
		}
		private function judge(e:MouseEvent):void{
			var wVec:Vector.<uint>=new Vector.<uint>();//该变量很重要，它可以让matchUnsuccessfully()函数在不该调用的时候不调用。详见下面的“重要”标记。
			for(var w in wordAry){
				wVec.push(w);
				if(wordTF.text==wordAry[w]){//我不知道为何写成 "==String(resultXML.words.word[w])" 没用。
				    recordW=w;
					score+=wordTF.length;
				    matchSuccessfully();
					break;
				}else{
					if(wVec.length==wordAry.length){//“重要”：如果没有这行判断，即便满足"textGained==wordAry[w]",matchUnsuccessfully()也往往会在matchSuccessfully()被调用之前被调用。
						matchUnsuccessfully();
					}
				}
				
			}
			activateRefreshBtn();
		}
		private function matchSuccessfully():void{
			wordTF.text="";
			explainer(String(resultXML.words.word[recordW].@enExplain+"      "+resultXML.words.word[recordW].@cnExplain));
			for(var k in clickedCards){
				var lie:uint=clickedCards[k].col;
				var hang:uint=clickedCards[k].ro;
				removeChild(cards[lie][hang]);
				cards[lie][hang]=null;//虽然要移除的卡片在cards里面被设为null了,但是clickedCards里面还持有该卡片的引用,这也方便了后来我们利用该卡片的col,ro属性.

				if(cards[lie].choosedTimes==2){
					for(var i:uint=0;i<6;i++){
						letWhomFall(cards[lie][i]);
					}
				}else{
					for(var j:uint=0;j<hang;j++){
						letWhomFall(cards[lie][j]);
					}
				}
				
		    }
			refreshScore();//更新分数
            deleteSomeElements();//先为某些数组删除所有应该删除的卡片元素
			supply();//再新创建一些卡片，并设置好他们的col,ro,letter属性,保存在suppliedCards里面,但不添加到cards里面的数组中，只是留作后用。
			addSomeElements();//再为某些数组添加数量正好的卡片元素。
			addEventListenerForNewBottom();//然后，要考虑添加时间侦听器的问题了。
			showNewTop();//最后，把suppliedCards里面的卡片显示在顶部（可能是第一行，也可能是第二行）
			clickedCards.length=0;
			stopOKBtn();
		}
		private function refreshScore():void{
			scoreTF.defaultTextFormat=new TextFormat("Verdana",30,0xff00ff);
			scoreTF.autoSize="left";
			scoreTF.x=290;
			scoreTF.y=50;
			scoreTF.text="SCORE:"+String(score);
			addChild(scoreTF);
		}
		private function letWhomFall(whom:Card):void{
			whom.y+=spacing;
			whom.ro+=1;
		}
		private function deleteSomeElements():void{
			for(var k in clickedCards){
				var lie:uint=clickedCards[k].col;
				var hang:uint=clickedCards[k].ro;
				if(cards[lie].length>=hang){
					cards[lie].splice(hang,1);
				}else{
					cards[lie].splice(hang-1,1);
				}
			}
		}
		private function supply():void{
			suppliedCards=new Vector.<Card>();
			for(var k in clickedCards){
				var lie:uint=clickedCards[k].col;
				if(cards[lie].choosedTimes>0){
					var newCard:Card=new Card();
					dispatchLetter();
					newCard.addChild(letterTF);
					newCard.letter=letterTF.text;
					newCard.col=lie;
					newCard.ro=cards[lie].choosedTimes-1;//这一行写得很巧妙
					suppliedCards.push(newCard);
					cards[lie].choosedTimes--;
				}
			}

		}
		private function addSomeElements():void{
			for(var k in clickedCards){
				var lie:uint=clickedCards[k].col;
				cards[lie].unshift(suppliedCards[k]);
			}
		}
		private function addEventListenerForNewBottom():void{//有时候会存在重复添加情况，比如最后一行的不是降落下来的，而是一开始就在那，就又为它添加了一次。
			for(var k in clickedCards){                     //再比如，这个for循环可能会得到两个同样的lie变量，这样，更是重复添加了事件侦听器。
				var lie:uint=clickedCards[k].col;
				addEventListenerFor(cards[lie][6]);
				addEventListenerFor(cards[lie][7]);
			}
		}
		private function showNewTop():void{
			//trace(suppliedCards.length);
			for(var k in suppliedCards){
				var lie:uint=suppliedCards[k].col;
				var hang:uint=suppliedCards[k].ro;
				cards[lie][hang].x=lie*spacing+offsetX;
				cards[lie][hang].y=hang*spacing+offsetY;
				addChild(cards[lie][hang]);
			}
			suppliedCards.length=0;
		}
		
		private function matchUnsuccessfully():void{
			reminder("抱歉，未匹配到该缩略词。");
			addEventListener(Event.ENTER_FRAME,removeRemindTF);
			wordTF.text="";
			for(var k in clickedCards){
				var lie:uint=clickedCards[k].col;
				var hang:uint=clickedCards[k].ro;
				cards[lie].choosedTimes--;
				cards[lie][hang].alpha=1;
				cards[lie][hang].addEventListener(MouseEvent.MOUSE_OVER,mouse_over);
				cards[lie][hang].addEventListener(MouseEvent.MOUSE_OUT,mouse_out);
				cards[lie][hang].removeEventListener(MouseEvent.CLICK,quitChoosing);
				cards[lie][hang].addEventListener(MouseEvent.CLICK,chooseCard);
				cards[lie][hang].removeEventListener(MouseEvent.MOUSE_OVER,remind);
			}
			clickedCards.length=0;
			okBtn.alpha=.2;
			okBtn.mouseEnabled=false;
		}
		private function explainer(txt:String):void{
			explainTF.defaultTextFormat=new TextFormat("Verdana",30,0x002277);
			explainTF.wordWrap=true;
			explainTF.text=txt;
			explainTF.width=350;
			explainTF.height=200;
			explainTF.x=300;
			explainTF.y=250;
			addChild(explainTF);
		}
		private function activateOKBtn():void{
			if(clickedCards.length>1){
				okBtn.alpha=1;
			    okBtn.mouseEnabled=true;
				okBtn.addEventListener(MouseEvent.CLICK,judge);
			}
		}
		private function activateRefreshBtn():void{
			refreshBtn.alpha=1;
			refreshBtn.mouseEnabled=true;
			
		}
		private function stopOKBtn():void{
			okBtn.alpha=.2;
			okBtn.mouseEnabled=false;
		}
		private function stopRefreshBtn():void{
			refreshBtn.alpha=0.2;
			refreshBtn.mouseEnabled=false;
		}


	}
}

