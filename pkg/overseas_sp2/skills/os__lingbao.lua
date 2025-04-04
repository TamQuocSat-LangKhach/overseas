local os__lingbao = fk.CreateSkill {
  name = "os__lingbao"
}

Fk:loadTranslationTable{
  ['os__lingbao'] = '灵宝',
  ['os__cinnabar'] = '丹',
  ['#os__lingbao-red'] = '灵宝：选择一名角色，令其回复1点体力',
  ['#os__lingbao-black'] = '灵宝：选择一名角色，弃置其至多两个不同区域的各一张牌',
  ['#os__lingbao-discard'] = '弃置其至多两个不同区域的各一张牌',
  ['os__lingbao_discard'] = '灵宝',
  ['#os__lingbao-black_red'] = '灵宝：选择两名角色，先选的摸一张牌，后选的弃置一张牌',
  [':os__lingbao'] = '出牌阶段限一次，你可将两张花色不同的“丹”置入弃牌堆，若：均为红色，你令一名角色回复1点体力；均为黑色，你弃置一名角色至多两个不同区域的各一张牌；颜色不同，你令一名角色摸一张牌，另一名角色弃置一张牌。',
  ['$os__lingbao1'] = '洞明于至道，俯弘于世教。',
  ['$os__lingbao2'] = '凝神太虚镜，北冥探玄珠。',
}

os__lingbao:addEffect('active', {
  can_use = function(self, player)
    return player:usedSkillTimes(os__lingbao.name, Player.HistoryPhase) < 1 and #player:getPile("os__cinnabar") > 1
  end,
  card_num = 2,
  expand_pile = "os__cinnabar",
  card_filter = function(self, player, to_select, selected)
    return (#selected == 0 or (#selected == 1 and Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(selected[1]), true))) and player:getPileNameOfId(to_select) == "os__cinnabar"
  end,
  target_num = 0,
  on_use = function(self, room, use)
    if #use.cards ~= 2 then return end
    local player = room:getPlayerById(use.from)
    room:moveCardTo(use.cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, os__lingbao.name)
    local color = table.map(use.cards, function(id) return Fk:getCardById(id).color end)
    if color[1] == color[2] then
      if color[1] == Card.Red then
        local availableTargets = table.map(
          table.filter(room.alive_players, function(p)
            return p:isWounded()
          end), Util.IdMapper)
        if #availableTargets == 0 then return false end
        local target = room:askToChoosePlayers(player, {
          targets = availableTargets,
          min_num = 1,
          max_num = 1,
          prompt = "#os__lingbao-red",
          skill_name = os__lingbao.name,
          cancelable = false,
        })
        if #target > 0 then
          room:recover({ who = target[1], num = 1, recoverBy = player, skillName = os__lingbao.name})
        end
      else
        local availableTargets = table.map(
          table.filter(room.alive_players, function(p)
            return not p:isAllNude()
          end),
          Util.IdMapper
        )
        if #availableTargets == 0 then return false end
        local target = room:askToChoosePlayers(player, {
          targets = availableTargets,
          min_num = 1,
          max_num = 1,
          prompt = "#os__lingbao-black",
          skill_name = os__lingbao.name,
          cancelable = false,
        })
        if #target > 0 then
          target = room:getPlayerById(target[1])
          local card_data = {}
          local data = {
            to = target.id,
            skillName = os__lingbao.name,
          }
          local visible_data = {}
          local cards = target:getCardIds(Player.Hand)
          if #cards > 0 then
            table.insert(card_data, {"$Hand", cards})
            for _, id in ipairs(cards) do
              if not player:cardVisible(id) then
                visible_data[tostring(id)] = false
              end
            end
            if next(visible_data) == nil then visible_data = nil end
            data.visible_data = visible_data
          end
          local areas = {["$Equip"] = Player.Equip, ["$Judge"] = Player.Judge}
          for k, v in pairs(areas) do
            if #target.player_cards[v] > 0 then
              table.insert(card_data, {k, target:getCardIds(v)})
            end
          end
          cards = room:askToPoxi(player, {
            poxi_type = "os__lingbao_discard",
            data = card_data,
            extra_data = data,
            cancelable = false,
          })
          room:throwCard(cards, os__lingbao.name, target, player)
        end
      end
    else
      local targets = room:askToChoosePlayers(player, {
        targets = table.map(room.alive_players, Util.IdMapper),
        min_num = 2,
        max_num = 2,
        prompt = "#os__lingbao-black_red",
        skill_name = os__lingbao.name,
        cancelable = false,
      })
      if #targets > 0 then
        room:getPlayerById(targets[1]):drawCards(1, os__lingbao.name)
        targets = room:getPlayerById(targets[2])
        if not targets:isNude() then
          room:askToDiscard(targets, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = os__lingbao.name,
            cancelable = false,
          })
        end
      end
    end
  end,
})

return os__lingbao
