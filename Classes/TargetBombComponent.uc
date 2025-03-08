class TargetBombComponent extends TargetGoatComponent;

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	super.KeyState(newKey, keyState, PCOwner);

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if(localInput.IsKeyIsPressed( "GBA_Special", string( newKey ) ))
		{
			if(bLocked && theTarget != none)
			{
				myMut.Spawn( class'CustomBombActor', gMe, , GetPawnPosition(theTarget) + vect(0, 0, 1500));
			}
		}
	}
}
