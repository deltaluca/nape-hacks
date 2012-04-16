import nape.space.Space;
import nape.phys.Body;
import nape.constraint.PivotJoint;
import nape.shape.Polygon;
import nape.shape.Circle;
import nape.geom.Vec2;
import nape.util.ShapeDebug;

import nape.hacks.ForcedSleep;

class Main {
	static function main() {
		var c = flash.Lib.current;

		var debug = new ShapeDebug(c.stage.stageWidth,c.stage.stageHeight);
		c.addChild(debug.display);
		var space = new Space(new Vec2(0,400));

		var border = new Body(nape.phys.BodyType.STATIC);
		border.shapes.add(new Polygon(Polygon.rect(0,500,500,50)));
		border.shapes.add(new Polygon(Polygon.rect(500,0,50,500)));
		border.shapes.add(new Polygon(Polygon.rect(0,0,500,-50)));
		border.shapes.add(new Polygon(Polygon.rect(0,0,-50,500)));
		border.space = space;

		for(i in 0...25) {
			var box = new Body();
			box.shapes.add(new Polygon(Polygon.box(15,15)));
			box.position.setxy(100*Std.int(i/5)+50,100*(i%5)+50);
			ForcedSleep.addSleepingBody(space,box);

			var circle = new Body();
			circle.shapes.add(new Circle(15));
			circle.position.set(box.position);
			circle.position.y += 35;
			ForcedSleep.addSleepingBody(space,circle);

			var mid = box.position.add(circle.position).mul(0.5);
			var link = new PivotJoint(box,circle,box.worldToLocal(mid),circle.worldToLocal(mid));
			ForcedSleep.addSleepingConstraint(space,link);
		}

		var hand = new PivotJoint(space.world,null,new Vec2(), new Vec2());
		hand.active = false;
		hand.space = space;
		hand.stiff = false;

		c.stage.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function (_) {
			var mp = new Vec2(c.mouseX,c.mouseY);
			for(b in space.bodiesUnderPoint(mp)) {
				hand.body2 = b;
				hand.anchor2 = b.worldToLocal(mp);
				hand.active = true;
				break;
			}
		});
		c.stage.addEventListener(flash.events.MouseEvent.MOUSE_UP, function (_) hand.active = false);

		(new haxe.Timer(17)).run = function() {
			hand.anchor1.setxy(c.mouseX,c.mouseY);
			space.step(1/60);
			debug.clear();
			debug.draw(space);
		}
	}
}
