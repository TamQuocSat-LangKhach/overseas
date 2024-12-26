local extension = Package("overseas_sp3")
extension.extensionName = "overseas"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["overseas_sp3"] = "国际服专属3",
  ["os_mou"] = "国际谋",
}

local licuilianquanding = General(extension, "licuilianquanding", "shu", 3, 3, General.Bigender)
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
      if player.room:askForSkillInvoke(player, self.name, data) then
        self.cost_data = nil
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local num = math.min(10, target.hp * 2)
      local cards = room:getNCards(num)
      room:moveCards{
        ids = cards,
        toArea = Card.Processing,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        proposer = player.id,
      }

      local cardmap = room:askForArrangeCards(player, self.name, {cards, "Top", "os__protect"}, "#os__ciyin-get", true, 0,
      nil, nil, ".|.|heart,spade")
      if #cardmap[2] > 0 then
        player:addToPile("os__protect", cardmap[2], true, self.name, player.id)
      end
      if #cardmap[1] > 0 then
        room:moveCards{
          ids = table.reverse(cardmap[1]),
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
          moveVisible = false,
        }
      end
      if player.dead then return end
      local choices = {"os__ciyin_recover", "os__ciyin_draw"}
      local tongxin_choice = {}
      local companion = player:getMark("_os__ciyin") ---@type integer
      if #player:getPile("os__protect") >= 3 and player:getMark("_os__ciyin_choice") == 0 then
        local choice = room:askForChoice(player, choices, self.name, companion == 0 and "#os__ciyin_only-choose" or "#os__ciyin-choose::" .. companion)
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
  [":os__ciyin"] = "你或<a href='os__coop'>同心角色</a>的准备阶段，你可亮出牌堆顶的X张牌（X为当前回合角色体力值的两倍且至多为10），" ..
    "将其中任意张♠或<font color='red'>♥</font>牌置于你的武将牌上，称为“荫”，然后将其余牌置于牌堆顶。你每获得三张“荫”，须执行一项本局" ..
    "游戏未执行过的<a href='os__coop'>同心效果</a>：1.加1点体力上限并回复1点体力；2.将手牌摸至体力上限。",
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
  ["~licuilianquanding"] = "（李翠莲）吾儿，前路坎坷，为母恐不能再行……（全定）母亲！母亲……",
}

local moucaopi = General(extension, "os_mou__caopi", "wei", 3)
local moucaopiwin = fk.CreateActiveSkill{ name = "os_mou__caopi_win_audio" }
moucaopiwin.package = extension
Fk:addSkill(moucaopiwin)
Fk:loadTranslationTable{
  ["os_mou__caopi"] = "谋曹丕",
  ["#os_mou__caopi"] = "魏文帝",
  ["illustrator:os_mou__caopi"] = "蛋勒个蛋蛋蛋蛋蛋",
  ["$os_mou__xingshang1"] = "众士出生入死，孤当敛而奠之。",
  ["$os_mou__xingshang2"] = "身既死兮神以灵，魂魄毅兮为鬼雄。",
  ["$os_mou__fangzhu1"] = "朕于天下无所不容，而况汝乎？",
  ["$os_mou__fangzhu2"] = "世子之争素来如此，朕予改封已是仁慈！",
  ["$os_mou__songwei1"] = "朕之玉言，可决万民生死！",
  ["$os_mou__songwei2"] = "受禅汉庭，德大可参日月！",
  ["~os_mou__caopi"] = "此战无功而返，我军锐气已失……",
  ["$os_mou__caopi_win_audio"] = "昔始皇一统六国，朕平吴蜀何尝不可？",
}

local mouxingshang = fk.CreateActiveSkill{
  name = "os_mou__xingshang",
  anim_type = "support",
  prompt = "#os_mou__xingshang",
  card_num = 0,
  target_num = 1,
  interaction = function(self)
    local deadPlayers = table.filter(Fk:currentRoom().players, function(p) return p.dead end)
    local choiceList = {
      "os_mou__xingshang_restore",
      "os_mou__xingshang_draw:::" .. math.min(5, math.max(2, #deadPlayers)),
      "os_mou__xingshang_recover",
      "os_mou__xingshang_memorialize",
    }
    local choices = {}
    local markValue = Self:getMark("@os_mou__xingshang_song")
    if markValue > 1 then
      table.insertTable(choices, { choiceList[1], choiceList[2] })
    end
    if markValue > 4 then
      table.insert(choices, choiceList[3])
      if 
        table.find(
          deadPlayers,
          function(p)
            return p.rest < 1 and not table.contains(Fk:currentRoom():getBanner('memorializedPlayers') or {}, p.id)
          end
        )
      then
        local skills = Fk.generals[Self.general]:getSkillNameList()
        if Self.deputyGeneral ~= "" then
          table.insertTableIfNeed(skills, Fk.generals[Self.deputyGeneral]:getSkillNameList())
        end

        if table.find(skills, function(skillName) return skillName == self.name end) then
          table.insert(choices, "os_mou__xingshang_memorialize")
        end
      end
    end

    return UI.ComboBox { choices = choices, all_choices = choiceList }
  end,
  times = function(self)
    return Self.phase == Player.Play and 2 - Self:getMark("mou__xingshang_used-phase") or -1
  end,
  can_use = function(self, player)
    return player:getMark("os_mou__xingshang_used-phase") < 2 and player:getMark("@os_mou__xingshang_song") > 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected > 0 then
      return false
    end

    local interactionData = self.interaction.data
    if interactionData == "os_mou__xingshang_recover" then
      return Fk:currentRoom():getPlayerById(to_select).maxHp < 10
    elseif interactionData == "os_mou__xingshang_memorialize" then
      return to_select == Self.id
    end

    return true
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addPlayerMark(player, "os_mou__xingshang_used-phase")

    local choice = self.interaction.data
    if choice == "os_mou__xingshang_restore" then
      room:removePlayerMark(player, "@os_mou__xingshang_song", 2)
      target:reset()
    elseif choice:startsWith("os_mou__xingshang_draw") then
      room:removePlayerMark(player, "@os_mou__xingshang_song", 2)
      local deadPlayersNum = #table.filter(room.players, function(p) return not p:isAlive() end)
      target:drawCards(math.min(5, math.max(2, deadPlayersNum)), self.name)
    elseif choice == "os_mou__xingshang_recover" then
      room:removePlayerMark(player, "@os_mou__xingshang_song", 5)
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
      if target.dead then return end
      room:changeMaxHp(target, 1)

      if not target.dead and #target.sealedSlots > 0 then
        room:resumePlayerArea(target, {table.random(target.sealedSlots)})
      end
    elseif choice == "os_mou__xingshang_memorialize" then
      room:removePlayerMark(player, "@os_mou__xingshang_song", 5)
      local zhuisiPlayers = room:getBanner('memorializedPlayers') or {}
      table.insertIfNeed(zhuisiPlayers, target.id)
      room:setBanner('memorializedPlayers', zhuisiPlayers)

      local availablePlayers = table.map(table.filter(room.players, function(p)
        return not p:isAlive() and p.rest < 1 and not table.contains(room:getBanner('memorializedPlayers') or {}, p.id)
      end), Util.IdMapper)
      local toId
      local result = room:askForCustomDialog(
        target, self.name,
        "packages/mougong/qml/ZhuiSiBox.qml",
        { availablePlayers, "$MouXingShang" }
      )

      if result == "" then
        toId = table.random(availablePlayers)
      else
        toId = json.decode(result).playerId
      end

      local to = room:getPlayerById(toId)
      local skills = Fk.generals[to.general]:getSkillNameList()
      if to.deputyGeneral ~= "" then
        table.insertTableIfNeed(skills, Fk.generals[to.deputyGeneral]:getSkillNameList())
      end
      skills = table.filter(skills, function(skill_name)
        local skill = Fk.skills[skill_name]
        return not skill.lordSkill and not (#skill.attachedKingdom > 0 and not table.contains(skill.attachedKingdom, target.kingdom))
      end)
      if #skills > 0 then
        room:handleAddLoseSkills(target, table.concat(skills, "|"))
      end

      room:setPlayerMark(target, "@os_mou__xingshang_memorialized", to.deputyGeneral ~= "" and "seat#" .. to.seat or to.general)
      room:handleAddLoseSkills(player, "-" .. self.name .. '|-os_mou__fangzhu|-os_mou__songwei')
    end
  end,

  on_lose = function (self, player)
    local room = player.room
    room:setPlayerMark(player, "os_mou__xingshang_used-phase", 0)
    room:setPlayerMark(player, "os_mou__xingshang_damaged-turn", 0)
    room:setPlayerMark(player, "@os_mou__xingshang_song", 0)
  end
}
local mouxingshangTriggger = fk.CreateTriggerSkill{
  name = "#os_mou__xingshang_trigger",
  mute = true,
  main_skill = mouxingshang,
  events = {fk.Damaged, fk.Death},
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(mouxingshang) and
      player:getMark("@os_mou__xingshang_song") < 9 and
      (event ~= fk.Damaged or (player:getMark("os_mou__xingshang_damaged-turn") == 0 and data.to:isAlive()))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      room:setPlayerMark(player, "os_mou__xingshang_damaged-turn", 1)
    end

    room:addPlayerMark(player, "@os_mou__xingshang_song", math.min(2, 9 - player:getMark("@os_mou__xingshang_song")))
  end,
}
Fk:loadTranslationTable{
  ["os_mou__xingshang"] = "行殇",
  [":os_mou__xingshang"] = "当一名角色受到伤害后（此项每回合限一次）或死亡时，则你获得两枚“颂”标记（你至多拥有9枚“颂”标记）；出牌阶段限两次，" ..
  "你可选择一名角色并移去至少一枚“颂”令其执行对应操作：2枚，复原武将牌或摸X张牌（X为阵亡角色数，至少为2且至多为5）；5枚，" ..
  "回复1点体力并加1点体力上限，然后随机恢复一个已废除的装备栏（目标体力上限不大于9方可选择），或<a href='memorialize'>追思</a>一名已阵亡的角色（你选择自己且你的武将牌上有〖行殇〗时方可选择此项），" ..
  "获得其武将牌上除主公技外的所有技能（你选择自己且你的武将牌上有〖行殇〗技能时方可选择此项），然后你失去〖行殇〗、〖放逐〗、〖颂威〗。",
  ["#os_mou__xingshang"] = "放逐：你可选择一名角色，消耗一定数量的“颂”标记对其进行增益",
  ["#os_mou__xingshang_trigger"] = "行殇",
  ["$MouXingShang"] = "行殇",
  ["@os_mou__xingshang_song"] = "颂",
  ["@os_mou__xingshang_memorialized"] = "行殇",
  ["os_mou__xingshang_restore"] = "2枚：复原武将牌",
  ["os_mou__xingshang_draw"] = "2枚：摸%arg张牌",
  ["os_mou__xingshang_recover"] = "5枚：恢复体力与区域",
  ["os_mou__xingshang_memorialize"] = "5枚：追思技能",
}

mouxingshang:addRelatedSkill(mouxingshangTriggger)
moucaopi:addSkill(mouxingshang)

local moufangzhu = fk.CreateActiveSkill{
  name = "os_mou__fangzhu",
  anim_type = "control",
  prompt = "#os_mou__fangzhu",
  card_num = 0,
  target_num = 1,
  interaction = function(self)
    local choiceList = {
      "os_mou__fangzhu_only_basic",
      "os_mou__fangzhu_only_trick",
      "os_mou__fangzhu_only_equip",
      "os_mou__fangzhu_nullify_skill",
      "os_mou__fangzhu_disresponsable",
      "os_mou__fangzhu_turn_over",
    }
    local choices = {}
    for i = 1, math.min(Self:getMark("@os_mou__xingshang_song"), 3) do
      if i == 1 then
        table.insert(choices, "os_mou__fangzhu_only_basic")
      elseif i == 2 then
        table.insert(choices, "os_mou__fangzhu_only_trick")
        if not Fk:currentRoom():isGameMode("1v2_mode") then
          table.insert(choices, "os_mou__fangzhu_nullify_skill")
        end
        table.insert(choices, "os_mou__fangzhu_disresponsable")
      else
        if not Fk:currentRoom():isGameMode("1v2_mode") then
          table.insertTable(choices, { "os_mou__fangzhu_only_equip", "os_mou__fangzhu_turn_over" })
        end
      end
    end
    return UI.ComboBox { choices = choices, all_choices = choiceList }
  end,
  can_use = function(self, player)
    return
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      player:getMark("@os_mou__xingshang_song") > 0 and
      player:hasSkill(mouxingshang, true)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    local choice = self.interaction.data
    if choice:startsWith("os_mou__fangzhu_only") then
      choice = choice:sub(-5)
      room:removePlayerMark(player, "@os_mou__xingshang_song", choice == "basic" and 1 or (choice == "trick" and 2 or 3))
      local limit_mark = target:getTableMark("@os_mou__fangzhu_limit")
      table.insertIfNeed(limit_mark, choice.."_char")
      room:setPlayerMark(target, "@os_mou__fangzhu_limit", limit_mark)
    elseif choice == "os_mou__fangzhu_nullify_skill" then
      room:removePlayerMark(player, "@os_mou__xingshang_song", 2)
      room:setPlayerMark(target, "@@os_mou__fangzhu_skill_nullified", 1)
    elseif choice == "os_mou__fangzhu_disresponsable" then
      room:removePlayerMark(player, "@os_mou__xingshang_song", 2)
      room:setPlayerMark(target, "@@os_mou__fangzhu_disresponsable", 1)
    elseif choice == "os_mou__fangzhu_turn_over" then
      room:removePlayerMark(player, "@os_mou__xingshang_song", 3)
      target:turnOver()
    end
  end,
}
local moufangzhuRefresh = fk.CreateTriggerSkill{
  name = "#os_mou__fangzhu_refresh",
  refresh_events = { fk.AfterTurnEnd, fk.CardUsing },
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterTurnEnd then
      return
        target == player and
        table.find(
          { "@os_mou__fangzhu_limit", "@@os_mou__fangzhu_skill_nullified", "@@os_mou__fangzhu_disresponsable" },
          function(markName) return player:getMark(markName) ~= 0 end
        )
    end

    return
      target == player and
      table.find(
        player.room.alive_players,
        function(p) return p:getMark("@@os_mou__fangzhu_disresponsable") > 0 and p ~= target end
      )
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room

    if event == fk.AfterTurnEnd then
      for _, markName in ipairs({ "@os_mou__fangzhu_limit", "@@os_mou__fangzhu_skill_nullified", "@@os_mou__fangzhu_disresponsable" }) do
        if player:getMark(markName) ~= 0 then
          room:setPlayerMark(player, markName, 0)
        end
      end
    else
      data.disresponsiveList = data.disresponsiveList or {}
      local tos = table.filter(
        player.room.alive_players,
        function(p) return p:getMark("@@os_mou__fangzhu_disresponsable") > 0 and p ~= target end
      )
      table.insertTableIfNeed(data.disresponsiveList, table.map(tos, Util.IdMapper))
    end
  end,
}
local moufangzhuProhibit = fk.CreateProhibitSkill{
  name = "#os_mou__fangzhu_prohibit",
  prohibit_use = function(self, player, card)
    local typeLimited = player:getMark("@os_mou__fangzhu_limit")
    if typeLimited == 0 then return false end
    if table.every(Card:getIdList(card), function(id)
      return table.contains(player:getCardIds(Player.Hand), id)
    end) then
      return #typeLimited > 1 or typeLimited[1] ~= card:getTypeString() .. "_char"
    end
  end,
}
local moufangzhuNullify = fk.CreateInvaliditySkill {
  name = "#os_mou__fangzhu_nullify",
  invalidity_func = function(self, from, skill)
    return from:getMark("@@os_mou__fangzhu_skill_nullified") > 0 and skill:isPlayerSkill(from)
  end
}
Fk:loadTranslationTable{
  ["os_mou__fangzhu"] = "放逐",
  [":os_mou__fangzhu"] = "出牌阶段限一次，若你有“行殇”，则你可以选择一名其他角色，并移去至少一枚“颂”标记令其执行对应操作：1枚，" ..
  "直到其下个回合结束，其不能使用基本牌外的手牌；2枚，直到其下个回合结束，其所有技能失效或其不可响应除其外的角色使用的牌，" ..
  "或其不能使用锦囊牌外的手牌；3枚，其翻面或直到其下个回合结束，其不能使用装备牌外的手牌（若为斗地主，则令其他角色技能失效、" ..
  "只可使用装备牌及翻面的效果不可选择）。",
  ["#os_mou__fangzhu"] = "放逐：你可选择一名角色，消耗一定数量的“颂”标记对其进行限制",
  ["#os_mou__fangzhu_prohibit"] = "放逐",
  ["@os_mou__fangzhu_limit"] = "放逐限",
  ["@@os_mou__fangzhu_skill_nullified"] = "放逐 技能失效",
  ["@@os_mou__fangzhu_disresponsable"] = "放逐 不可响应",
  ["os_mou__fangzhu_only_basic"] = "1枚：只可使用基本牌",
  ["os_mou__fangzhu_only_trick"] = "2枚：只可使用锦囊牌",
  ["os_mou__fangzhu_only_equip"] = "3枚：只可使用装备牌",
  ["os_mou__fangzhu_nullify_skill"] = "2枚：武将技能失效",
  ["os_mou__fangzhu_disresponsable"] = "2枚：不可响应他人牌",
  ["os_mou__fangzhu_turn_over"] = "3枚：翻面",
}

moufangzhu:addRelatedSkill(moufangzhuRefresh)
moufangzhu:addRelatedSkill(moufangzhuProhibit)
moufangzhu:addRelatedSkill(moufangzhuNullify)
moucaopi:addSkill(moufangzhu)

local mousongwei = fk.CreateActiveSkill{
  name = "os_mou__songwei$",
  anim_type = "control",
  prompt = "#os_mou__songwei",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      table.find(Fk:currentRoom().alive_players, function(p) return p.kingdom == "wei" end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select).kingdom == "wei"
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local skills = Fk.generals[target.general]:getSkillNameList(true)
    if target.deputyGeneral ~= "" then
      table.insertTableIfNeed(skills, Fk.generals[target.deputyGeneral]:getSkillNameList(true))
    end
    if #skills > 0 then
      skills = table.map(skills, function(skillName) return "-" .. skillName end)
      room:handleAddLoseSkills(target, table.concat(skills, "|"), nil, true, false)
    end

    room:setPlayerMark(target, "@@os_mou__songwei_target", 1)
  end,
}
local mousongweiTrigger = fk.CreateTriggerSkill{
  name = "#os_mou__songwei_trigger",
  events = { fk.EventPhaseStart },
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Play and
      player:hasSkill(mousongwei) and
      player:hasSkill(mouxingshang, true) and
      player:getMark("@os_mou__xingshang_song") < 9 and
      table.find(player.room.alive_players, function(p) return p.kingdom == "wei" and p ~= player end)
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local weiNum = #table.filter(room.alive_players, function(p) return p.kingdom == "wei" and p ~= player end)
    room:addPlayerMark(player, "@os_mou__xingshang_song", math.min(weiNum * 2, 9 - player:getMark("@os_mou__xingshang_song")))
  end,
}
Fk:loadTranslationTable{
  ["os_mou__songwei"] = "颂威",
  [":os_mou__songwei"] = "主公技，出牌阶段开始时，若你有“行殇”，则你获得X枚“颂”标记（X为存活的其他魏势力角色数的两倍）；" ..
  "每局游戏限一次，出牌阶段，你可以令一名其他魏势力角色失去其武将牌上的所有技能。",
  ["#os_mou__songwei"] = "颂威：你可以让一名其他魏国角色失去技能",
  ["@@os_mou__songwei_target"] = "已颂威",
}

mousongwei:addRelatedSkill(mousongweiTrigger)
moucaopi:addSkill(mousongwei)

return extension
