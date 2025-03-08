class TargetAimComponent extends TargetGoatComponent;

/**
 * See super.
 */
function TickMutatorComponent( float deltaTime )
{
	local rotator NewRotation;
	
	super.TickMutatorComponent( deltaTime );
	
	if(bLocked && theTarget != none && !gMe.mIsRagdoll)
	{
		NewRotation = Rotator(Normal(theTarget.Location - gMe.Location));
		NewRotation.Roll = 0.f;
		NewRotation.Pitch = 0.f;
		gMe.SetRotation( NewRotation );
	}
}