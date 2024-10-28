
public class Set extends ScriptableService {
    private let m_value: array<Variant>;
    public let m_mutex: RWLock;

    private cb func OnReload() {
        this.Clear();
    }

    public func Size() -> Int32 {
        RWLock.AcquireShared(this.m_mutex);
        let size = ArraySize(this.m_value);
        RWLock.ReleaseShared(this.m_mutex);
        return size;
    }

    public func Add(value: Variant) -> Void {
        if NotEquals(this.Has(value), true) {
            RWLock.Acquire(this.m_mutex);
            ArrayPush(this.m_value, value);
            RWLock.Release(this.m_mutex);
        }
    }

    public func Clear() -> Void {
        RWLock.Acquire(this.m_mutex);
        ArrayClear(this.m_value);
        RWLock.Release(this.m_mutex);
    }

    public func Delete(value: Variant) -> Bool {
        if Equals(this.Has(value), true) {
            RWLock.Acquire(this.m_mutex);
            let res = ArrayRemove(this.m_value, value);
            RWLock.Release(this.m_mutex);
            return res;
        }
        return false;
    }

    public func Has(value: Variant) -> Bool {
        RWLock.AcquireShared(this.m_mutex);
        for item in this.m_value {
            if Equals(item, value) {
                RWLock.ReleaseShared(this.m_mutex);
                return true;
            }
        }
        RWLock.ReleaseShared(this.m_mutex);
        return false;
    }
}

@wrapMethod(ScriptedPuppet)
protected cb func OnKillRewardEvent(evt: ref<KillRewardEvent>) {
    wrappedMethod(evt);
    let victim = evt.victim;
    let ent = victim.GetEntity();
    let hash = victim.GetEntityID().GetHash();
    if IsDefined(victim) {
        LogChannel(n"DEBUG", s"\(ent) \(hash)");
    }
}

// let _set = GameInstance.GetScriptableServiceContainer().GetService(n"Set") as Set;
// let hash = EntityID.GetHash(evt.victim.GetEntityID());
// let totalSize: Int32 = 8;
// if Equals(hastag, true) {
//     _set.Add(hash);
//     if Equals(_set.Size() >= totalSize, true) {
//         let game = evt.victim.GetGame();
//         let fact = tagService.GetEnemyDefeatedFact();
//         SetFactValue(game, fact, 1);
//     }
// }
@wrapMethod(ShardCaseContainer)
protected cb func OnInteraction(choiceEvent: ref<InteractionChoiceEvent>) -> Bool {
    let currentReadedShardTweakID = this.itemTDBID;
    FTLog(s"On interact \(TDBID.ToStringDEBUG(currentReadedShardTweakID))");
    if Equals(currentReadedShardTweakID, t"Items.mq_kidnap_shard_1") {
        SetFactValue(this.GetGame(), n"kidnap_shard_1_found", 1);
    }
    if Equals(currentReadedShardTweakID, t"Items.mq_kidnap_shard_2") {
        SetFactValue(this.GetGame(), n"kidnap_shard_2_found", 1);
    }
    let result: Bool = wrappedMethod(choiceEvent);
    return result;
}
