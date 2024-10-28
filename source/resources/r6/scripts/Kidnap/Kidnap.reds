@wrapMethod(ShardCaseContainer)
protected cb func OnInteraction(choiceEvent: ref<InteractionChoiceEvent>) -> Bool {
    let currentReadedShardTweakID = this.itemTDBID;
    if Equals(currentReadedShardTweakID, t"Items.mq_kidnap_shard_1") {
        SetFactValue(this.GetGame(), n"kidnap_shard_1_found", 1);
    }
    if Equals(currentReadedShardTweakID, t"Items.mq_kidnap_shard_2") {
        SetFactValue(this.GetGame(), n"kidnap_shard_2_found", 1);
    }
    let result: Bool = wrappedMethod(choiceEvent);
    return result;
}
