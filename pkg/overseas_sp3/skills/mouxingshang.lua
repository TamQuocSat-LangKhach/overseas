local mouxingshang = fk.CreateSkill {
  name = "os_mou__xingshang"
}

Fk:loadTranslationTable{
  ['os_mou__xingshang'] = '行殇',
  ['#os_mou__xingshang'] = '放逐：你可选择一名角色，消耗一定数量的“颂”标记对其进行增益',
  ['os_mou__xingshang_restore'] = '2枚：复原武将牌',
  ['os_mou__xingshang_draw'] = '2枚：摸%arg张牌',
  ['os_mou__xingshang_recover'] = '5枚：恢复体力与区域',
  ['os_mou__xingshang_memorialize'] = '5枚：追思技能',
  ['@os_mou__xingshang_song'] = '颂',
  ['$MouXingShang'] = '行殇',
  ['@os_mou__xingshang_memorialized'] = '行殇',
  ['#os_mou__xingshang_trigger'] = '行殇',
  [':os_mou__xingshang'] = '当一名角色受到伤害后（此项每回合限一次）或死亡时，则你获得两枚“颂”标记（你至多拥有9枚“颂”标记）；出牌阶段限两次，你可选择一名角色并移去至少一枚“颂”令其执行对应操作：2枚，复原武将牌或摸X张牌（X为阵亡角色数，至少为2且至多为5）；5枚，回复1点体力并加1点体力上限，然后随机恢复一个已废除的装备栏（目标体力上限不大于9方可选择），或<a href=>追思</a>一名已阵亡的角色（你选择自己且你的武将牌上有〖行殇〗时方可选择此项），获得其武将牌上除主公技外的所有技能（你选择自己且你的武将牌上有〖行殇〗技能时方可选择此项），然后你失去〖行殇〗、〖放逐〗、〖颂威〗。',
  ['$os_mou__xingshang1'] = '众士出生入死，孤当敛而奠之。',
  ['$os_mou__xingshang2'] = '身既死兮神以灵，魂魄毅兮为鬼雄。',
}

mouxingshang:addEffect('active', {
  anim_type = "support",
  prompt = "#os_mou__xingshang",
  card_num = 0,
  target_num = 1,
  interaction = function(self, player)
    local deadPlayers = table.filter(Fk:currentRoom().players, function(p) return p.dead end)
    local choiceList = {
      "os_mou__xingshang_restore",
      "os_mou__xingshang_draw:::" .. math.min(5, math.max(2, #deadPlayers)),
      "os_mou__xingshang_recover",
      "os_mou__xingshang_memorialize",
    }
    local choices = {}
    local markValue = player:getMark("@os_mou__xingshang_song")
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
        local skills = Fk.generals[player.general]:getSkillNameList()
        if player.deputyGeneral ~= "" then
          table.insertTableIfNeed(skills, Fk.generals[player.deputyGeneral]:getSkillNameList())
        end

        if table.find(skills, function(skillName) return skillName == mouxingshang.name end) then
          table.insert(choices, "os_mou__xingshang_memorialize")
        end
      end
    end

    return UI.ComboBox { choices = choices, all_choices = choiceList }
  end,
  times = function(self, player)
    return player.phase == Player.Play and 2 - player:getMark("mou__xingshang_used-phase") or -1
  end,
  can_use = function(self, player)
    return player:getMark("os_mou__xingshang_used-phase") < 2 and player:getMark("@os_mou__xingshang_song") > 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected > 0 then
      return false
    end

    local interactionData = skill.interaction.data
    if interactionData == "os_mou__xingshang_recover" then
      return Fk:currentRoom():getPlayerById(to_select).maxHp < 10
    elseif interactionData == "os_mou__xingshang_memorialize" then
      return to_select == player.id
    end

    return true
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addPlayerMark(player, "os_mou__xingshang_used-phase")

    local choice = skill.interaction.data
    if choice == "os_mou__xingshang_restore" then
      room:removePlayerMark(player, "@os_mou__xingshang_song", 2)
      target:reset()
    elseif choice:startsWith("os_mou__xingshang_draw") then
      room:removePlayerMark(player, "@os_mou__xingshang_song", 2)
      local deadPlayersNum = #table.filter(room.players, function(p) return not p:isAlive() end)
      target:drawCards(math.min(5, math.max(2, deadPlayersNum)), mouxingshang.name)
    elseif choice == "os_mou__xingshang_recover" then
      room:removePlayerMark(player, "@os_mou__xingshang_song", 5)
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = mouxingshang.name,
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
      local result = room:askToCustomDialog(
        target,
        { skill_name = mouxingshang.name, qml_path = "packages/mougong/qml/ZhuiSiBox.qml", extra_data = { availablePlayers, "$MouXingShang" } }
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
      room:handleAddLoseSkills(player, "-" .. mouxingshang.name .. '|-os_mou__fangzhu|-os_mou__songwei')
    end
  end,

  on_lose = function (skill, player)
    local room = player.room
    room:setPlayerMark(player, "os_mou__xingshang_used-phase", 0)
    room:setPlayerMark(player, "os_mou__xingshang_damaged-turn", 0)
    room:setPlayerMark(player, "@os_mou__xingshang_song", 0)
  end
})

mouxingshang:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(mouxingshang.name) and
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
})

mouxingshang:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(mouxingshang.name) and
      player:getMark("@os_mou__xingshang_song") < 9
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room

    room:addPlayerMark(player, "@os_mou__xingshang_song", math.min(2, 9 - player:getMark("@os_mou__xingshang_song")))
  end,
})

return mouxingshang
