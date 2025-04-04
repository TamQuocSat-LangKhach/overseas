local os__zhiqu = fk.CreateSkill {
  name = "os__zhiqu"
}

Fk:loadTranslationTable{
  ['os__zhiqu'] = '直取',
  ['#os__zhiqu-ask'] = '你可对一名其他角色发动“直取”，依次亮出牌堆顶的 %arg 张牌，使用其中的一些牌',
  ['#os__zhiqu-targets'] = '直取：选择 你或/和%dest 成为 %arg 的目标',
  [':os__zhiqu'] = '结束阶段开始时，你可选择一名其他角色并依次亮出牌堆顶X张牌，对其使用其中的【杀】。（X为你至其距离1以内的角色数）若<a href=>搏击</a>：改为使用其中的【杀】和锦囊牌，这些牌只能指定你或其为目标。',
  ['$os__zhiqu1'] = '八百之众，哼，须臾可灭！',
  ['$os__zhiqu2'] = '此战首功，当由我取之！',
}

os__zhiqu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__zhiqu.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local num = #table.filter(room.alive_players, function(p) return player:distanceTo(p) <= 1 end)
    local target = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os__zhiqu-ask:::" .. num,
      skill_name = os__zhiqu.name,
      cancelable = true
    })
    if #target > 0 then
      event:setCostData(self, target[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local num = #table.filter(room.alive_players, function(p) return player:distanceTo(p) <= 1 end)
    local to = room:getPlayerById(event:getCostData(self))
    local wrestle = player:inMyAttackRange(to) and to:inMyAttackRange(player)
    room:setPlayerMark(player, MarkEnum.BypassTimesLimit, 1)
    room:setPlayerMark(player, MarkEnum.BypassDistancesLimit, 1)
    for i = 1, num, 1 do
      local id = room:getNCards(1)[1]
      room:moveCardTo(id, Card.Processing, nil, fk.ReasonJustMove, os__zhiqu.name)
      local card = Fk:getCardById(id)
      if (card.trueName == "slash" or card.name == "n_brick") and not player:prohibitUse(card) and not player:isProhibited(to, card) and not to.dead then --彩蛋
        room:useCard({
          card = card,
          from = player.id,
          tos = { {to.id} },
          skillName = os__zhiqu.name,
          extraUse = true,
        })
      end
      if wrestle and card.type == Card.TypeTrick and player:canUse(card) and not player:prohibitUse(card) then --大有问题
        local targets = {}
        if (table.contains({"savage_assault", "archery_attack", "duel", "enemy_at_the_gates", "drowning", "unexpectation", "raid_and_frontal_attack"}, card.name) or
          (table.contains({"snatch", "dismantlement", "chasing_near"}, card.name) and not to:isAllNude()) or 
          (card.name == "indulgence" and not to:hasDelayedTrick("indulgence")) or
          (card.name == "supply_shortage" and not to:hasDelayedTrick("supply_shortage"))) and not player:isProhibited(to, card) then
          table.insert(targets, to.id)
        end
        if table.contains({"amazing_grace", "god_salvation", "iron_chain", "redistribute", "underhanding", "fire_attack"}, card.name)
          and not (player:isProhibited(player, card) and player:isProhibited(to, card)) then
          targets = {player.id, to.id}
        end
        if table.contains({"ex_nihilo", "foresight"}, card.name) and not player:isProhibited(player, card) then
          table.insert(targets, player.id)
        end
        local use = {
          from = player.id,
          card = card,
          skillName = os__zhiqu.name,
        }
        if #targets == 1 then
          use.tos = { targets }
          room:useCard(use)
        elseif #targets > 1 then
          if table.contains({"amazing_grace", "god_salvation"}, card.name) then
            use.tos = { {player.id}, {to.id} }
            room:useCard(use)
          elseif card.skill:getMaxTargetNum(player, card) == 1 then
            local tar = room:askToChoosePlayers(player, {
              targets = targets,
              min_num = 1,
              max_num = 1,
              prompt = "#os__zhiqu-targets::" .. to.id .. ":" .. card:toLogString(),
              skill_name = os__zhiqu.name,
              cancelable = false
            })
            use.tos = { tar }
            room:useCard(use)
          elseif card.skill:getMaxTargetNum(player, card) > 1 then
            if table.contains({"iron_chain", "underhanding"}, card.name) then
              local tar = room:askToChoosePlayers(player, {
                targets = targets,
                min_num = 1,
                max_num = 2,
                prompt = "#os__zhiqu-targets::" .. to.id .. ":" .. card:toLogString(),
                skill_name = os__zhiqu.name,
                cancelable = false
              })
              use.tos = table.map(tar, function(pid) return { pid } end)
              room:useCard(use)
            else
              use.tos = {targets}
              room:useCard(use)
            end
          end
        end
      end
      room:cleanProcessingArea({id}, os__zhiqu.name)
    end
    room:setPlayerMark(player, MarkEnum.BypassTimesLimit, 0)
    room:setPlayerMark(player, MarkEnum.BypassDistancesLimit, 0)
  end,
})

return os__zhiqu
