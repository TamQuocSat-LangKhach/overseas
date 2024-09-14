local extension = Package("overseas_sp3")
extension.extensionName = "overseas"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["overseas_sp3"] = "国际服专属3",
}

local licuilianquanding = General(extension, "licuilianquanding", "qun", 3, 3, General.Bigender)
local os__ciyin = fk.CreateTriggerSkill{
  name = "os__ciyin",
  events = {fk.EventPhaseStart, fk.TurnStart},
  derived_piles = "os__protect",
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(self) then return end
    if event == fk.EventPhaseStart then
      return target.phase == Player.Start and (target == player or target.id == player:getMark("_os__ciyin"))
    else
      return target == player
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local targets = room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
        1, 1, "#os__ciyin-ask", self.name, true)
      if #targets > 0 then
        self.cost_data = {tos = targets}
        return true
      end
    else
      return player.room:askForSkillInvoke(player, self.name, data)
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local cards = room:getNCards(math.min(10, target.hp * 2))
      room:moveCards{
        ids = cards,
        toArea = Card.Processing,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        proposer = player.id,
      }
      local _cards = table.filter(cards, function(id) return (Fk:getCardById(id).suit == Card.Spade or Fk:getCardById(id).suit == Card.Heart) and room:getCardArea(id) == Card.Processing end)
      local to_get, choice = U.askforChooseCardsAndChoice(player, _cards, {"os__ciyin_getAll", "os__ciyin_getSelected"}, self.name, "#os__ciyin-get", nil, 0, #_cards, cards)
      if choice == "os__ciyin_getAll" then
        to_get = _cards
      end
      player:addToPile("os__protect", to_get, true, self.name, player.id)
      cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
      if #cards > 0 then
        room:askForGuanxing(player, cards, nil, {0, 0})
      end
      if player.dead then return end
      local choices = {"os__ciyin_recover", "os__ciyin_draw"}
      local tongxin_choice = {}
      local companion = player:getMark("_os__ciyin") ---@type integer
      if #player:getPile("os__protect") >= 3 and player:getMark("_os__ciyin_choice") == 0 then
        choice = room:askForChoice(player, choices, self.name, companion == 0 and "#os__ciyin_only-choose" or "#os__ciyin-choose::" .. companion)
        table.insert(tongxin_choice, choice)
        room:setPlayerMark(player, "_os__ciyin_choice", choice)
      end
      if #player:getPile("os__protect") >= 6 and player:getMark("_os__ciyin_choice") ~= "allDone" then
        table.removeOne(choices, player:getMark("_os__ciyin_choice"))
        table.insert(tongxin_choice, choices[1])
        room:setPlayerMark(player, "_os__ciyin_choice", "allDone")
      end
      if #tongxin_choice == 0 then return end
      local targets = {player.id}
      if companion ~= 0 then table.insert(targets, companion) end
      room:sortPlayersByAction(targets)
      for _, pid in ipairs(targets) do
        local p = room:getPlayerById(pid)
        if not p.dead then
          if table.contains(tongxin_choice, "os__ciyin_recover") then
            room:changeMaxHp(p, 1)
            if not p.dead then
              room:recover{
                who = p,
                num = 1,
                recoverBy = player,
                skillName = self.name
              }
            end
          end
          if table.contains(tongxin_choice, "os__ciyin_draw") and p.maxHp > p:getHandcardNum() then
            p:drawCards(p.maxHp - p:getHandcardNum(), self.name)
          end
        end
      end
    else
      local to = self.cost_data.tos[1]
      room:setPlayerMark(player, "@os__ciyin", room:getPlayerById(to).general)
      room:setPlayerMark(player, "_os__ciyin", to)
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__ciyin") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "_os__ciyin", 0)
    player.room:setPlayerMark(player, "@os__ciyin", 0)
  end,
}

local os__chenglong = fk.CreateTriggerSkill{
  name = "os__chenglong",
  events = {fk.EventPhaseStart},
  frequency = Skill.Wake,
  can_trigger = function (self, event, target, player, data)
    return
      player:hasSkill(self) and
      target.phase == Player.Finish and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function (self, event, target, player, data)
    return player:getMark("_os__ciyin_choice") == "allDone"
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:obtainCard(player, player:getPile("os__protect"), true, fk.ReasonPrey, player.id, self.name)
    if player.dead then return end
    room:handleAddLoseSkills(player, "-os__ciyin")
    if player.dead then return end
    local kingdoms = {"shu", "qun"}
    local generals, skillList = {}, {}
    local index = 1
    while #generals < 4 and index <= #room.general_pile do
      local g = room.general_pile[index]
      if (table.contains(kingdoms, Fk.generals[g].kingdom) or table.contains(kingdoms, Fk.generals[g].subkingdom)) then
        local skills = table.filter(Fk.generals[g]:getSkillNameList(false), function(s) return
          Fk.skills[s].frequency < Skill.Limited and (string.find(Fk:getDescription(s, "zh_CN"), "【杀】") or string.find(Fk:getDescription(s, "zh_CN"), "【闪】"))
        end)
        if #skills > 0 then
          table.insert(generals, table.remove(room.general_pile, index))
          table.insert(skillList, skills)
        else
          index = index + 1
        end
      else
        index = index + 1
      end
    end
    local choice = {}
    if #generals == 0 then return false else choice = {skillList[1]} end
    if #generals > 0 then
      local result = player.room:askForCustomDialog(player, self.name,
      "packages/tenyear/qml/ChooseGeneralSkillsBox.qml", {
        generals, skillList, 1, 2, "#os__chenglong-choice", false
      })
      if result ~= "" then
        choice = json.decode(result)
      end
      room:handleAddLoseSkills(player, table.concat(choice, "|"), nil)
      room:returnToGeneralPile(generals, "bottom")
    end
  end
}

licuilianquanding:addSkill(os__ciyin)
licuilianquanding:addSkill(os__chenglong)

Fk:loadTranslationTable{
  ["licuilianquanding"] = "李翠莲全定",
  ["#licuilianquanding"] = "望子成龙",

  ["os__ciyin"] = "慈荫",
  [":os__ciyin"] = "你或同心角色的准备阶段，你可亮出牌堆顶的X张牌（X为当前回合角色体力值的两倍且至多为10），" ..
    "将其中任意张♠或<font color='red'>♥</font>牌置于你的武将牌上，称为“荫”，然后将其余牌置于牌堆顶。你每获得三张“荫”，须执行一项本局" ..
    "游戏未执行过的同心效果：1.加1点体力上限并回复1点体力；2.将手牌摸至体力上限。" ..
    "<br/><font color='grey'>#\"<b>同心</b>\"：回合开始时，你可选择一名其他角色为你的同心角色，直到你的下个回合开始；执行同心效果时，你先执行，然后若你有同心角色，其执行。</font>",
  ["os__chenglong"] = "成龙",
  [":os__chenglong"] = "觉醒技，一名角色的结束阶段，若你已执行过〖慈荫〗的所有选项，你获得武将牌上所有“荫”，" ..
    "然后失去〖慈荫〗，从四张蜀势力或群势力武将牌中选择并获得至多两个描述中含有“【杀】”或“【闪】”的技能（觉醒技、限定技、使命技、主公技除外）。",

  ["os__protect"] = "荫",
  ["#os__ciyin-get"] = "慈荫：将任意张♠或<font color='red'>♥</font>牌置于你的武将牌上，称为“荫”，将其余牌置于牌堆顶",
  ["os__ciyin_getAll"] = "将全部黑桃或红桃牌作为“荫”",
  ["os__ciyin_getSelected"] = "将选择的黑桃或红桃牌作为“荫”",
  ["os__ciyin_recover"] = "加1点体力上限并回复1点体力",
  ["os__ciyin_draw"] = "将手牌摸至体力上限",
  ["#os__ciyin-choose"] = "慈荫：选择一项同心效果，你和 %dest 执行",
  ["#os__ciyin_only-choose"] = "慈荫：选择一项同心效果，仅你执行",
  ["@os__ciyin"] = "慈荫同心",
  ["#os__ciyin-ask"] = "你可选择一名其他角色成为你的 慈荫 同心角色",
  ["#os__chenglong-choice"] = "成龙：选择并获得至多两个技能",

  ["$os__ciyin1"] = "虽为纤弱之身，亦当为吾儿遮风挡雨。",
  ["$os__ciyin2"] = "纵有狼虎于前，定保吾儿平安。",
  ["$os__chenglong1"] = "这次，换孩儿来保护母亲！",
  ["$os__chenglong2"] = "儿虽年幼，亦当立丈夫之志！",
  ["~licuilianquanding"] = "（李翠莲）吾儿，前路坎坷，为母恐不能再行。（全定）母亲，母亲……",
}

return extension
