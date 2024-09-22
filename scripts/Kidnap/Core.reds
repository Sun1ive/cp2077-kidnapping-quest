
class TagService extends ScriptableService {
    public func GetShardOneReadFact() -> CName {
        return n"kidnap_shard_1_read";
    }

    public func GetShardTwoReadFact() -> CName {
        return n"kidnap_shard_2_read";
    }
}

@wrapMethod(ShardCaseContainer)
protected cb func OnInteraction(choiceEvent: ref<InteractionChoiceEvent>) -> Bool {
    let tagService = GameInstance.GetScriptableServiceContainer().GetService(n"TagService") as TagService;
    let currentReadedShardTweakID = this.itemTDBID;
    // FTLog(s"On interact \(TDBID.ToStringDEBUG(currentReadedShardTweakID))");
    if Equals(currentReadedShardTweakID, t"Items.mq_kidnap_shard_1") {
        SetFactValue(this.GetGame(), tagService.GetShardOneReadFact(), 1);
    }
    if Equals(currentReadedShardTweakID, t"Items.mq_kidnap_shard_2") {
        SetFactValue(this.GetGame(), tagService.GetShardTwoReadFact(), 1);
    }
    let result: Bool = wrappedMethod(choiceEvent);
    return result;
}
