package nape.hacks;

import nape.phys.Body;
import nape.constraint.Constraint;
import nape.phys.Compound;
import nape.space.Space;

import zpp_nape.dynamics.Arbiter;

@:keep class ForcedSleep {
	public static function sleepBody(body:Body) {
		if(body==null) throw "Error: Can't force sleep null body";
		if(body.space==null) throw "Error: This hack requires the Body to already be in a Space!";
		if(body==body.space.world) throw "Error: Cannot force sleep space.world!";
		if(body.space.zpp_inner.midstep) throw "Error: Even this hack can't operate from within space.step()!";

		var b = body.zpp_inner;
		if(b.component.sleeping) return;
		b.component.sleeping = true;

		//remove from live object lists.
		if(body.isDynamic()) b.space.live.remove(b);
		else {
			if(body.isKinematic())
				b.space.kinematics.remove(b);
			b.space.staticsleep.remove(b);
		}

		//force any arbiters to be put to sleep.
		var arbi = b.arbiters.head;
		while(arbi!=null) {
			var arb = arbi.elt;
			if(arb.cleared || arb.sleeping) { arbi = arbi.next; continue; }

			arb.sleeping = true;
			arb.sleep_stamp = b.space.stamp;

			if(arb.type==ZPP_Arbiter.COL) {
				var carb = arb.colarb;
				if(carb.stat) b.space.c_arbiters_true.remove(carb);
				else          b.space.c_arbiters_false.remove(carb);
			}else if(arb.type==ZPP_Arbiter.FLUID)
			     b.space.f_arbiters.remove(arb.fluidarb);
			else b.space.s_arbiters.remove(arb.sensorarb);

			arbi = arbi.next;
		}

		if(!b.space.bphase.is_sweep)
			for(s in body.shapes) b.space.bphase.sync(s.zpp_inner);
	}

	public static function sleepConstraint(constraint:Constraint) {
		if(constraint==null) throw "Error: Can't force sleep null constraint";
		if(constraint.space==null) throw "Error: This hack requires the Constraint to already be in a Space";
		if(constraint.space.zpp_inner.midstep) throw "Error: Even this hack can't operate from within space.step()!";

		var c = constraint.zpp_inner;
		if(c.component.sleeping) return;
		c.component.sleeping = true;

		c.space.live_constraints.remove(c);
	}

	//sleep this body, and all bodies connected via constraints + those constraints
	public static function sleepConnected(body:Body) {
		if(body==null) throw "Error: Can't force sleep connected from null Body";
		if(body.space==null) throw "Error: This hack requires the Body to already be in a Space";

		var set = new IntHash<Body>();
		var stack = [body];
		while(stack.length>0) {
			var b = stack.pop();
			if(set.exists(b.id)) continue;

			set.set(b.id,b);
			for(c in b.constraints)
				c.visitBodies(function (b) stack.unshift(b));
		}

		for(b in set) {
			if(b.space==null) throw "Error: This hack requires Body's to already be in a Space regarding body found during sleepConnected";

			if(b!=b.space.world) 
				sleepBody(b);

			for(c in b.constraints) sleepConstraint(c);
		}
	}

	//should be used in preference to adding, then sleeping
	public static function addSleepingBody(space:Space, body:Body) {
		if(body==null) throw "Error: Cannot add null body to Space";
		if(space==null) throw "Error: Cannot add body to null Space";

		if(body.space==space) { sleepBody(body); return; }
		else if(body.space!=null) body.space = null;

		var b = body.zpp_inner;
		var s = space.zpp_inner;
		//mostly copied from PR(Space)::addBody
		b.space = s;
		b.addedToSpace();
		b.component.sleeping = true;

		//mostly copied from PR(Space)::wake (well the one line anyways :D)
		b.component.waket = s.stamp+1; //not sure about this btw :)
		//addedToSpace will deal with broadphase with actual insertion
		//for dyn-aabb being deferred until step at which point body
		//is asleep and will be inserted into correct tree :)

		//mostly copied from PR(Space)::addBody
		for(shape in body.shapes) s.added_shape(shape.zpp_inner,true);
		if(body.isStatic())
			s.static_validation(b);

		//aaaand one extra step not present in addBody because
		//of how bodies are added
		s.bodies.add(b);

		//also need to do this for non-statics to operate with
		//broadphases correctly
		//mostly copied from PR(Space)::validation
		if(!body.isStatic()) {
			b.validate_mass();
			b.validate_inertia();
			b.validate_aabb();
			b.validate_gravMass();
			b.validate_worldCOM();
			b.validate_axis();
		
			for(shape in body.shapes) {	
				var s = shape.zpp_inner;
				if(s.isPolygon())
					s.polygon.validate_gaxi();
			}
		}
	}

	//should be used in preference to adding, then sleeping
	public static function addSleepingConstraint(space:Space, constraint:Constraint) {
		if(constraint==null) throw "Error: Cannot add null constraint to Space";
		if(space==null) throw "Error: Cannot add constraint to null Space";

		if(constraint.space==space) { sleepConstraint(constraint); return; }
		else if(constraint.space!=null) constraint.space = null;

		var c = constraint.zpp_inner;
		var s = space.zpp_inner;
		//mostly copied from PR(Space)::addConstraint
		c.space = s;
		c.addedToSpace();
		if(c.active) {
			c.component.sleeping = true;
			//mostly copied from PR(Space)::wake_constraint
			c.component.waket = s.stamp+1; //not sure about this :)
		}

		//also need to do this! (here only)
		s.constraints.add(c);
	}

	//should be used in preference to adding, then sleeping
	public static function addSleepingCompound(space:Space, compound:Compound) {
		if(compound==null) throw "Error: Cannot add null compound to Space";
		if(space==null) throw "Error: Cannot add compound to null Space";

		if(compound.space==space) {
			compound.visitBodies(sleepBody);
			compound.visitConstraints(sleepConstraint);
		}else if(compound.space!=null) compound.space = null;

		var c = compound.zpp_inner;
		var s = space.zpp_inner;
		//mostly copied from PR(Space)::addCompound
		c.space = s;
		c.addedToSpace();
		for(b in compound.bodies) addSleepingBody(space,b);
		for(c in compound.constraints) addSleepingConstraint(space,c);
		for(c in compound.compounds) addSleepingCompound(space,c);
	}
}
