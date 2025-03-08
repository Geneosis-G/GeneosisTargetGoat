class TargetSwapComponent extends TargetGoatComponent;

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	super.KeyState(newKey, keyState, PCOwner);

	if(PCOwner != gMe.Controller)
		return;

	if( keyState == KS_Down )
	{
		if( newKey == 'X' || newKey == 'XboxTypeS_LeftTrigger')
		{
			DoSwap();
		}
	}
}

function DoSwap()
{
	local GGGoat goatTarget;
	local GGNpc npcTarget;
	local vector goatDest, targetDest;
	//No spawp when riding a vehicle
	if(gMe.DrivenVehicle != none || theTarget.DrivenVehicle != none)
		return;

	npcTarget = GGNpc(theTarget);
	goatTarget = GGGoat(theTarget);
	goatDest=GetPawnPosition(theTarget);
	targetDest=GetPawnPosition(gMe);

	if(npcTarget != none || goatTarget != none)
	{
		SetPawnPosition(gMe, GetSwapLocation(gMe, goatDest));
		SetPawnPosition(theTarget, GetSwapLocation(theTarget, targetDest));
	}
}

function vector GetSwapLocation( GGPawn gpawn, vector dest )
{
	local Actor itemActor, hitActor;
	local vector spawnLocation, itemExtent, itemExtentOffset, traceStart, traceEnd, traceExtent, hitLocation, hitNormal;
	local box itemBoundingBox;

	spawnLocation = GetPawnPosition(gpawn);

	itemActor = gpawn;
	if( itemActor != none )
	{
		spawnLocation = dest + vect(0, 0, 1) * gpawn.GetCollisionHeight();

		itemActor.GetComponentsBoundingBox( itemBoundingBox );

		itemExtent = ( itemBoundingBox.Max - itemBoundingBox.Min ) * 0.5f;
		itemExtentOffset = itemBoundingBox.Min + ( itemBoundingBox.Max - itemBoundingBox.Min ) * 0.5f - itemActor.Location;

		// Now try fit the thingy into the world.
		// Trace downward.
		traceStart = spawnLocation;
		traceEnd = spawnLocation - vect( 0, 0, 1 ) * itemExtent.Z;
		traceExtent = itemExtent;

		hitActor = gpawn.Trace( hitLocation, hitNormal, traceEnd, traceStart, false, traceExtent );
		if( hitActor == none )
		{
			hitLocation = traceEnd;
		}

		// The bounding box's location is not the same as the actors location so we need an offset.
		spawnLocation = hitLocation - itemExtentOffset;

		//DrawDebugLine( traceStart, traceEnd, 255, 255, 0, true );
		//DrawDebugSphere( hitLocation, 10.0f, 16, 255, 255, 0, true );
		//DrawDebugBox( spawnLocation, vect( 10, 10, 10 ), 255, 255, 0, true );
		//DrawDebugBox( hitLocation, traceExtent, 255, 255, 255, true );
	}
	else
	{
		`Log( "GetSwapLocation failed to find spawn point for item actor " $ itemActor );
	}

	return spawnLocation;
}

function SetPawnPosition(GGPawn gpawn, vector pos)
{
	local EPhysics oldPhysics;
	local bool oldCollideAct, oldBlockAct, oldMeshCollideAct, oldMeshBlockAct, oldMeshBlockRigid;

	oldPhysics=gpawn.Physics;
	gpawn.SetPhysics(PHYS_None);
	oldCollideAct=gpawn.bCollideActors;
	oldBlockAct=gpawn.bBlockActors;
	oldMeshCollideAct=gpawn.mesh.CollideActors;
	oldMeshBlockAct=gpawn.mesh.BlockActors;
	oldMeshBlockRigid=gpawn.mesh.BlockRigidBody;
	gpawn.SetCollision(false, false);
	gpawn.mesh.SetActorCollision(false, false);
	gpawn.mesh.SetBlockRigidBody(false);

	gpawn.mesh.SetRBPosition(pos);
	gpawn.SetLocation(pos);

	gpawn.SetPhysics(oldPhysics);
	gpawn.SetCollision(oldCollideAct, oldBlockAct);
	gpawn.mesh.SetActorCollision(oldMeshCollideAct, oldMeshBlockAct);
	gpawn.mesh.SetBlockRigidBody(oldMeshBlockRigid);
}

defaultproperties
{

}