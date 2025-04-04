local os__qirang = fk.CreateSkill {
  name = "os__qirang"
}

Fk:loadTranslationTable{
  ['os__qirang'] = '祈禳',
  ['@@os__qirang-phase-inhand'] = '祈禳',
  ['#os__qirang_trick'] = '祈禳',
  ['#os__qirang-target'] = '祈禳：你可为 %arg 增加或减少一个目标',
  [':os__qirang'] = '当装备牌移至你的装备区后，你可获得牌堆里的一张锦囊牌，然后你此阶段使用此牌无距离限制、不可被响应且可增加或减少一个目标。',
  ['$os__qirang1'] = '仙甲既来，岂无仙术乎。',
  ['$os__qirang2'] = '集母亲之智，效父亲之法，祈以七星。',
}

os__qirang:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os__qirang.name) then return false end
    for _, move in ipairs(data) do
      if move.to and move.to == player.id and move.toArea == Player.Equip then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cids = room:getCardsFromPileByRule(".|.|.|.|.|trick")
    if #cids > 0 then
      local cid = cids[1]
      room:addTableMark(player, "_os__qirangTrick-phase", cid)
      room:obtainCard(player, cid, false, fk.ReasonPrey, player.id, os__qirang.name, "@@os__qirang-phase-inhand")
    end
  end,
})

os__qirang:addEffect("targetmod", {
  name = "#os__qirang_buff",
  anim_type = "offensive",
  bypass_distances = function (skill, player, skill2, card, to)
    return card and table.contains(player:getTableMark("_os__qirangTrick-phase"), card.id)
  end,
})

os__qirang:addEffect({fk.AfterCardTargetDeclared, fk.CardUsing}, {
  name = "#os__qirang_trick",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.type == Card.TypeTrick and table.contains(player:getTableMark("_os__qirangTrick-phase"), data.card.id)
      and (event == fk.CardUsing or data.card.sub_type ~= Card.SubtypeDelayedTrick)
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardTargetDeclared then
      local room = player.room
      local targets = room:getUseExtraTargets(data)
      table.insertTableIfNeed(targets, TargetGroup:getRealTargets(data.tos))
      if #targets == 0 then return false end
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__qirang-target:::"..data.card:toLogString(),
        skill_name = os__qirang.name,
        cancelable = true,
        no_indicate = false,
        target_tip_name = "addandcanceltarget_tip",
      }, TargetGroup:getRealTargets(data.tos))
      if #tos > 0 then
        event:setCostData(skill, {tos = tos})
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardTargetDeclared then
      local room = player.room
      room:notifySkillInvoked(player, "os__qirang", "special")
      player:broadcastSkillInvoke("os__qirang")
      local to = event:getCostData(skill).tos[1]
      if TargetGroup:includeRealTargets(data.tos, to) then
        TargetGroup:removeTarget(data.tos, to)
      else
        table.insert(data.tos, {to})
        room:sendLog{
          type = "#AddTargetsBySkill",
          from = player.id,
          to = {to},
          arg = os__qirang.name,
          arg2 = data.card:toLogString()
        }
      end
    else
      data.disresponsiveList = data.disresponsiveList or {}
      for _, target in ipairs(player.room.players) do
        table.insertIfNeed(data.disresponsiveList, target.id)
      end
    end
  end,
})

return os__qirang
