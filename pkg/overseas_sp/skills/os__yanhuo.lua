local os__yanhuo = fk.CreateSkill {
  name = "os__yanhuo"
}

Fk:loadTranslationTable{
  ['os__yanhuo'] = '延祸',
  ['os__yanhuo_x'] = '令至多%arg名角色各弃置一张牌',
  ['os__yanhuo_1'] = '令一名角色弃置%arg张牌',
  ['#os__yanhuo-target_x'] = '延祸：选择至多 %arg 名角色，各弃置一张牌',
  ['#os__yanhuo-target_1'] = '延祸：选择一名角色，令其弃置 %arg 张牌',
  [':os__yanhuo'] = '当你死亡时，你可选择一项：1. 令至多X名角色各弃置一张牌；2. 令一名角色弃置X张牌，不足则全弃（X为你的牌数）。',
  ['$os__yanhuo1'] = '你很快就笑不出来了……',
  ['$os__yanhuo2'] = '乱世，才刚刚开始……',
}

os__yanhuo:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__yanhuo.name, false, true)
  end,
  on_cost = function(self, event, target, player)
    local num = #player:getCardIds(Player.Equip) + #player:getCardIds(Player.Hand)
    local choices = {"os__yanhuo_x:::" .. num, "os__yanhuo_1:::" .. num, "Cancel"}
    if num == 0 then return false 
    elseif num == 1 then choices = {"os__yanhuo_1:::" .. 1, "Cancel"} end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = os__yanhuo.name
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return (not p:isNude())
    end),
      Util.IdMapper)
    if #targets == 0 then return false end
    local choice = event:getCostData(self)
    local num = #player:getCardIds(Player.Equip) + #player:getCardIds(Player.Hand)
    if choice == "os__yanhuo_x:::" .. num then
      local p = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = num,
        prompt = "#os__yanhuo-target_x:::" .. tostring(num),
        skill_name = os__yanhuo.name
      })
      if #p > 0 then
        table.forEach(p, function(pid)
          room:askToDiscard(room:getPlayerById(pid), {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = os__yanhuo.name
          })
        end)
      end
    else
      local p = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__yanhuo-target_1:::" .. tostring(num),
        skill_name = os__yanhuo.name
      })
      if #p > 0 then
        local target = room:getPlayerById(p[1])
        if #target:getCardIds(Player.Equip) + #target:getCardIds(Player.Hand) <= num then
          target:throwAllCards("he")
        else
          room:askToDiscard(target, {
            min_num = num,
            max_num = num,
            include_equip = true,
            skill_name = os__yanhuo.name
          })
        end
      end
    end
  end,
})

return os__yanhuo
