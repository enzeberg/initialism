package  {
	import flash.display.Sprite;
	public class Card extends Sprite{
        public var col:uint;
		public var ro:uint;
		public var letter:String;
		public function Card() {
			this.graphics.lineStyle(1);
			this.graphics.beginFill(0x772244);
			this.graphics.drawRect(-19,0,38,38);
			this.graphics.endFill();
		}

	}
	
}
