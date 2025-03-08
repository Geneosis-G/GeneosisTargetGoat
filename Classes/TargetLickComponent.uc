class TargetLickComponent extends TargetGoatComponent;

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;
	local bool grabbedSuccessfully;

	super.KeyState(newKey, keyState, PCOwner);

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if(localInput.IsKeyIsPressed( "GBA_AbilityBite", string( newKey ) ))
		{
			if(gMe.mGrabbedItem == none)
			{
				grabbedSuccessfully = GrabItem(theTarget, GetPawnPosition(theTarget));

				if( grabbedSuccessfully )
				{
					GGGameInfo( myMut.WorldInfo.Game ).OnUseAbility(gMe, gMe.mAbilities[ EAT_Bite ], theTarget);
				}
			}
		}
	}
}

/**
 * Tries to grab an item.
 *
 * @param item - the item we wish to grab.
 *
 * @return - true if grabbed successfully; otherwise false.
 */
function bool GrabItem( Actor item, vector grabLocation )
{
	local GGPlayerControllerGame ggPC;
	local GGKactor kActor;
	local GGNpc npc;
	local GGGoat goat;
	local GGInterpActor interpActor;
	local name boneName;
	local PrimitiveComponent grabComponent;
	local GGGameInfo GGGI;

	if(item == none)
	{
		return false;
	}

	kActor = GGKActor( item );
	npc = GGNpc( item );
	goat = GGGoat( item );
	interpActor = GGInterpActor( item );

	if( kActor != none )
	{
		boneName = '';
		grabComponent = kActor.CollisionComponent;
	}
	else if( npc != none )
	{
		boneName = npc.mesh.FindClosestBone( grabLocation );

		if( boneName == 'None' || npc.Mesh.FindBodyInstanceNamed( boneName ) == none )
		{
			return false;
		}

		grabComponent = npc.mesh;
		npc.SetRagdoll( true );
	}
	else if( goat != none )
	{
		boneName = goat.mesh.FindClosestBone( grabLocation );

		if( boneName == 'None' || goat.Mesh.FindBodyInstanceNamed( boneName ) == none )
		{
			return false;
		}

		grabComponent = goat.mesh;
		goat.SetRagdoll( true );
	}
	else if( interpActor != none )
	{
		gMe.SetRagdoll( true );
		grabComponent = interpActor.CollisionComponent;
	}

	// Grab the item.
	gMe.mGrabber.GrabComponent( grabComponent, boneName, grabLocation, false );
	gMe.mActorsToIgnoreBlockingBy.AddItem( item );
	gMe.mGrabbedItem = item;

	if( GGScoreActorInterface( item ) != none )
	{
		if( GGScoreActorInterface( item ).GetActorName() == "Hang Glider" )
		{
			GGGI = GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game );
			ggPC = GGPlayerControllerGame(GGGI.GetALocalPlayerController());
			ggPC.mAchievementHandler.UnlockAchievement( ACH_MILE_HIGH_CLUB );
		}
	}

	gMe.SetTongueActive( true );

	return true;
}