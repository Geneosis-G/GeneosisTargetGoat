class TargetRagdollComponent extends TargetGoatComponent;

function OnRagdoll( Actor ragdolledActor, bool isRagdoll )
{
	if(ragdolledActor == gMe)
	{
		if(isRagdoll)
		{
			theTarget.SetRagdoll(true);
		}
		else
		{
			if(GGAIController(theTarget.Controller) != none)
			{
				GGAIController(theTarget.Controller).StandUp();
			}
			else
			{
				if(GGGoat(theTarget) != none) GGGoat(theTarget).StandUp();
				if(GGNpc(theTarget) != none) GGNpc(theTarget).StandUp();
			}
		}
	}
}

