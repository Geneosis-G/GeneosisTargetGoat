class TargetGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGPawn theTarget;
var bool bLocked;
var SkeletalMeshComponent mHaloMesh;
var array<GGPawn> blackList;
var GGMutator myMut;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	if(PCOwner != gMe.Controller)
		return;

	if( keyState == KS_Down )
	{
		if( newKey == 'TWO' || newKey == 'XboxTypeS_LeftShoulder')
		{
			if(!bLocked)
			{
				BlackListTarget();
			}
		}

		if( newKey == 'THREE' || newKey == 'XboxTypeS_RightShoulder')
		{
			if(bLocked)
			{
				UnlockTarget();
			}
			else
			{
				LockTarget();
				ClearBlackList();
			}
		}
	}
}

/**
 * See super.
 */
function TickMutatorComponent( float deltaTime )
{
	local GGPawn gpawn;
	local SkeletalMeshComponent haloMesh;

	gpawn = GetClosestVisiblePawn();

	if(gpawn != theTarget)
	{
		//Sometimes the halo can be deleted if your target go out of the map
		if(mHaloMesh == none)
		{
			haloMesh = new class'SkeletalMeshComponent';
			haloMesh.SkeletalMesh=SkeletalMesh'goat.Mesh.Gloria_01';
			mHaloMesh=haloMesh;
		}

		theTarget = gpawn;
		AttachTargetCircle();
	}
}

/**
 * Get the Pawn closer to the player visible by the camera
 */
function GGPawn GetClosestVisiblePawn()
{
	local GGPawn gpawn, CurrentPawn;

	if(bLocked)
	{
		CurrentPawn = theTarget;
	}
	else
	{
		CurrentPawn = none;

		foreach myMut.VisibleCollidingActors(class'GGPawn', gpawn, 7500, GetPawnPosition(gMe))
		{
			if(gpawn != none
			&& gpawn != gMe
			&& blackList.Find(gpawn) == INDEX_NONE)
			{
				if(CurrentPawn == none || (VSize(GetPawnPosition(gpawn) - GetPawnPosition(gMe)) < VSize(GetPawnPosition(CurrentPawn) - GetPawnPosition(gMe))))
				{
					CurrentPawn = gpawn;
				}
			}
		}
	}

	return CurrentPawn;
}

function vector GetPawnPosition(GGPawn gpawn)
{
	return gpawn.mIsRagdoll?gpawn.mesh.GetPosition():gpawn.Location;
}

/**
 * Attach a circle to the target so that the player can see it
 */
function AttachTargetCircle()
{
	local array<name> tBones;
	local name tmpBone, mBone;

	if(theTarget != none)
	{
		mHaloMesh.SetLightEnvironment( theTarget.mesh.LightEnvironment );
		mBone = '';
		theTarget.mesh.GetBoneNames(tBones);
		foreach tBones(tmpBone)
		{
			if(tmpBone == 'Head' || tmpBone == 'Ear_R' || tmpBone == 'Blowhole')
			{
				mBone = tmpBone;
				break;
			}
		}
		if(mBone != '')
		{
			theTarget.mesh.AttachComponent( mHaloMesh, mBone, vect(0, 0, 25));
		}
		else
		{
			theTarget.mesh.AttachComponent( mHaloMesh, 'Root', vect(0, 0, 1) * (theTarget.GetCollisionHeight() + 25.f));
		}
	}
	else
	{
		mHaloMesh.DetachFromAny();
	}
}

/**
 * Add the current target to the blacklist (allow target selection)
 */
function BlackListTarget()
{
	blackList.AddItem(theTarget);
}

/**
 * Clear the blacklist
 */
function ClearBlackList()
{
	blackList.Length=0;//This empty the array
}

/**
 * Lock the target
 */
function LockTarget()
{
	if(!bLocked)
	{
		bLocked = True;
		mHaloMesh.SetScale(mHaloMesh.scale * 1.5f);
		//WorldInfo.Game.Broadcast(self, "Pawn : " $ theTarget);
	}
}

/**
 * Unlock the target
 */
function UnlockTarget()
{
	if(bLocked)
	{
		bLocked = False;
		mHaloMesh.SetScale(mHaloMesh.scale / 1.5f);
	}
}

defaultproperties
{
	Begin Object class=SkeletalMeshComponent Name=haloMesh
		SkeletalMesh=SkeletalMesh'goat.Mesh.Gloria_01'
	End Object
	mHaloMesh=haloMesh
}