class TargetResizeComponent extends TargetGoatComponent;

var bool mIsLickPressed;
var float mJumpMultiplier;

var array<float> mSavedValues;

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	super.KeyState(newKey, keyState, PCOwner);

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		//myMut.WorldInfo.Game.Broadcast(myMut, newKey);
		//XboxTypeS_RightShoulder
		//XboxTypeS_RightTrigger
		if( newKey == 'G' || newKey == 'XboxTypeS_DPad_Up')
		{
			ResizeTarget(0.5f);
		}

		if( newKey == 'H' || newKey == 'XboxTypeS_DPad_Down')
		{
			ResizeTarget(2.0f);
		}

		if(localInput.IsKeyIsPressed("GBA_AbilityBite", string( newKey )))
		{
			mIsLickPressed=true;
		}
	}
	else if( keyState == KS_Up )
	{
		if(localInput.IsKeyIsPressed("GBA_AbilityBite", string( newKey )))
		{
			mIsLickPressed=false;
		}
	}
}

/**
 * Resize the target
 */
function ResizeTarget(float multiplier)
{
	local float newScale, oldScale, oldJumpScale, newJumpScale, mNewCollisionRadius, mNewCollisionHeight, offset;
	local GGCameraModeOrbital orbitalCamera;
	local vector v;
	local bool targetWasRagdoll;
	local int diplayScale, i;
	local GGGoat targetGoat;
	local GGNpc targetNpc;

	local SkeletalMesh mOldMesh;
	local PhysicsAsset mOldPhysAsset;
	local AnimTree	 mOldAnimTree;
	local AnimSet		 mOldAnimSet;
	local MaterialInterface mOldMaterial;

	targetGoat=GGGoat(theTarget);
	targetNpc=GGNpc(theTarget);

	if(targetGoat == none && targetNpc == none)
		return;

	oldScale = theTarget.DrawScale;
	newScale = oldScale * multiplier;

	if(myMut.WorldInfo.Game.GameSpeed >= 1.0f && !myMut.WorldInfo.bPlayersOnly && newScale < 1.0f/8.0f)
	{
		newScale = 1.0f/8.0f;
	}

	if(myMut.WorldInfo.Game.GameSpeed >= 1.0f && !myMut.WorldInfo.bPlayersOnly && newScale > 8.0f)
	{
		newScale = 8.0f;
	}

	oldJumpScale = mJumpMultiplier ** Loge(oldScale)/Loge(2);
	newJumpScale = mJumpMultiplier ** Loge(newScale)/Loge(2);

	targetWasRagdoll = (theTarget.Physics == PHYS_RigidBody);
	if(targetWasRagdoll)// Fix wrong mesh alignment if rescale heppen when ragdolled
	{
		theTarget.CollisionComponent = theTarget.mesh;
		theTarget.SetPhysics( PHYS_Falling );
		theTarget.SetRagdoll( false );
	}

	if(oldScale != newScale)
	{
		//Display scale to the player
		if(newScale >= 1)
		{
			diplayScale=newScale;
			myMut.WorldInfo.Game.Broadcast(myMut, "x" $ diplayScale);
		}
		else
		{
			diplayScale=1.0/newScale;
			myMut.WorldInfo.Game.Broadcast(myMut, "x1/" $ diplayScale);
		}


		if(mIsLickPressed)//Easter egg (glitchy ragdoll scale)
		{
			//Change mesh scale
			theTarget.SetDrawScale(newScale);
		}
		else
		{
			//FIX ragdoll scale !!!!!!!!!!!!!!!!
			mOldMesh = theTarget.mesh.SkeletalMesh;
			mOldPhysAsset = theTarget.mesh.PhysicsAsset;
			mOldAnimTree = theTarget.mesh.AnimTreeTemplate;
			mOldAnimSet = theTarget.mesh.AnimSets[ 0 ];
			mOldMaterial = theTarget.mesh.GetMaterial( 0 );
			theTarget.mesh.SetSkeletalMesh( none );
			theTarget.mesh.SetPhysicsAsset( none );
			theTarget.mesh.SetMaterial( 0, none );
			theTarget.mesh.SetAnimTreeTemplate( none );// Need proper NPC anim tree for this to work.
			theTarget.mesh.AnimSets[0] = none;

			//Change mesh scale
			theTarget.SetDrawScale(newScale);

			theTarget.mesh.SetSkeletalMesh( mOldMesh );
			theTarget.mesh.SetPhysicsAsset( mOldPhysAsset );
			theTarget.mesh.SetMaterial( 0, mOldMaterial );
			theTarget.mesh.SetAnimTreeTemplate( mOldAnimTree );// Need proper NPC anim tree for this to work.
			theTarget.mesh.AnimSets[0] = mOldAnimSet;
			//END fix ragdoll scale !!!!!!!!!!!!!!!!
			if(targetGoat != none) targetGoat.FetchTongueControl();
		}

		//Change collision box scale
		mNewCollisionRadius=theTarget.GetCollisionRadius() * (1/oldScale) * newScale;
		mNewCollisionHeight=theTarget.GetCollisionHeight() * (1/oldScale) * newScale;

		offset =  mNewCollisionHeight - theTarget.GetCollisionHeight();
		theTarget.SetCollisionSize( mNewCollisionRadius, mNewCollisionHeight );
		theTarget.SetLocation( theTarget.Location + vect( 0.0f, 0.0f, 1.0f ) * offset);

		if(targetGoat != none)
		{
			//Change camera position and some other parameters
			v.x = 0.0f;
			v.y = mNewCollisionRadius;
			v.z = mNewCollisionHeight;
			targetGoat.mCameraLookAtOffset = v;

			if(PlayerController( targetGoat.Controller ) != none)
			{
				orbitalCamera = GGCameraModeOrbital(GGCamera( PlayerController( targetGoat.Controller ).PlayerCamera ).mCameraModes[ CM_ORBIT ]);
				if(orbitalCamera != none)
				{
					orbitalCamera.mMaxZoomDistance = orbitalCamera.mMaxZoomDistance * (1/oldScale) * newScale;
					orbitalCamera.mMinZoomDistance = orbitalCamera.mMinZoomDistance * (1/oldScale) * newScale;
					orbitalCamera.mDesiredZoomDistance = orbitalCamera.mDesiredZoomDistance * (1/oldScale) * newScale;
					orbitalCamera.mCurrentZoomDistance = orbitalCamera.mCurrentZoomDistance * (1/oldScale) * newScale;
					orbitalCamera.mZoomUnit = orbitalCamera.mZoomUnit * (1/oldScale) * newScale;
				}
			}

			//Change abilities range
			for(i=0 ; i<targetGoat.mAbilities.Length ; i++)
			{
				targetGoat.mAbilities[i].mRange = targetGoat.mAbilities[i].mRange * (1/oldScale) * newScale;
			}

			//If the scale is bigger than x1, change the target speed
			if((multiplier > 1 && newScale > 1.0f) || (multiplier < 1 && newScale >= 1.0f))
			{
				if(oldScale < 1.f)// Just in case
					oldScale=1.f;

				targetGoat.mWalkSpeed = targetGoat.mWalkSpeed * (1/oldScale) * newScale;
				targetGoat.mStrafeSpeed = targetGoat.mStrafeSpeed * (1/oldScale) * newScale;
				targetGoat.mReverseSpeed = targetGoat.mReverseSpeed * (1/oldScale) * newScale;
				targetGoat.mSprintSpeed = targetGoat.mSprintSpeed * (1/oldScale) * newScale;
				targetGoat.GroundSpeed = targetGoat.GroundSpeed * (1/oldScale) * newScale;
				targetGoat.mWalkAccelRate = targetGoat.mWalkAccelRate * (1/oldScale) * newScale;
				targetGoat.mReverseAccelRate = targetGoat.mReverseAccelRate * (1/oldScale) * newScale;
				targetGoat.mSprintAccelRate = targetGoat.mSprintAccelRate * (1/oldScale) * newScale;
				targetGoat.AccelRate = targetGoat.AccelRate * (1/oldScale) * newScale;
				targetGoat.AirSpeed = targetGoat.AirSpeed * (1/oldScale) * newScale;
				targetGoat.mDecelerateInterpSpeed = targetGoat.mDecelerateInterpSpeed * (1/oldScale) * newScale;
				targetGoat.mWaterAccelRate = targetGoat.mWaterAccelRate * (1/oldScale) * newScale;
				targetGoat.mMaxSpeed = targetGoat.mSprintSpeed * 2.0f;
				targetGoat.CalcDesiredGroundSpeed();
				targetGoat.JumpZ = targetGoat.JumpZ * (1/oldJumpScale) * newJumpScale;

				targetGoat.mMinWallRunZ = targetGoat.mMinWallRunZ * (1/oldScale) * newScale;
				targetGoat.mWallRunZ = targetGoat.mWallRunZ * (1/oldScale) * newScale;
				targetGoat.mWallRunBoostZ = targetGoat.mWallRunBoostZ * (1/oldScale) * newScale;
				targetGoat.mWallRunSpeed = targetGoat.mWallRunSpeed * (1/oldScale) * newScale;
				targetGoat.mWallJumpZ = targetGoat.mWallJumpZ * (1/oldJumpScale) * newJumpScale;

				targetGoat.mRagdollLandSpeed = targetGoat.mRagdollLandSpeed * (1/oldScale) * newScale;
				targetGoat.mRagdollCollisionSpeed = targetGoat.mWalkSpeed + ( targetGoat.mSprintSpeed - targetGoat.mWalkSpeed ) * 0.5f;
				targetGoat.mRagdollJumpZ = targetGoat.mRagdollJumpZ * (1/oldJumpScale) * newJumpScale;

				targetGoat.mSpiderRunOffLedgeSpeed = targetGoat.mWalkSpeed + ( targetGoat.mSprintSpeed - targetGoat.mWalkSpeed ) * 0.1f;
			}
		}
	}

	if(targetWasRagdoll) theTarget.SetRagdoll( true );

	if(GGAIController(theTarget.Controller) != none) GGAIController(theTarget.Controller).ResumeDefaultAction();
}

function SaveCameraValues(Controller C)
{
	local GGCameraModeOrbital orbitalCamera;

	mSavedValues.Length=0;
	orbitalCamera = GGCameraModeOrbital(GGCamera( PlayerController( C ).PlayerCamera ).mCameraModes[ CM_ORBIT ]);
	if(orbitalCamera != none)
	{
		mSavedValues.AddItem(orbitalCamera.mMaxZoomDistance);
		mSavedValues.AddItem(orbitalCamera.mMinZoomDistance);
		mSavedValues.AddItem(orbitalCamera.mDesiredZoomDistance);
		mSavedValues.AddItem(orbitalCamera.mCurrentZoomDistance);
		mSavedValues.AddItem(orbitalCamera.mZoomUnit);
	}
}

function LoadCameraValues(Controller C)
{
	local GGCameraModeOrbital orbitalCamera;
	local int index;

	if(mSavedValues.Length == 0)
		return;

	orbitalCamera = GGCameraModeOrbital(GGCamera( PlayerController( C ).PlayerCamera ).mCameraModes[ CM_ORBIT ]);
	if(orbitalCamera != none)
	{
		orbitalCamera.mMaxZoomDistance = mSavedValues[index++];
		orbitalCamera.mMinZoomDistance = mSavedValues[index++];
		orbitalCamera.mDesiredZoomDistance = mSavedValues[index++];
		orbitalCamera.mCurrentZoomDistance = mSavedValues[index++];
		orbitalCamera.mZoomUnit = mSavedValues[index++];
	}
	mSavedValues.Length=0;
}

function ModifyCameraZoom( GGGoat goat )
{
	super.ModifyCameraZoom(goat);

	LoadCameraValues(goat.Controller);
}

function ResetCameraZoom( Controller C )
{
	SaveCameraValues(C);

	super.ResetCameraZoom(C);
}

defaultproperties
{
	mJumpMultiplier=1.4142135f // sqrt(2)
	//1.259921f // CubeSquare(2)
}
