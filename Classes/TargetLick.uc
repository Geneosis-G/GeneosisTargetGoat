class TargetLick extends TargetGoat;

/**
 * if the mutator should be selectable in the Custom Game Menu.
 */
static function bool IsUnlocked( optional out array<AchievementDetails> out_CachedAchievements )
{
	return True;
}

DefaultProperties
{
	mMutatorComponentClass=class'TargetLickComponent'
}