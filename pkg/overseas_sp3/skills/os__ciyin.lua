local os__ciyin = fk.CreateSkill {
  name = "os__ciyin"
}

Fk:loadTranslationTable{
  ['os__ciyin'] = '慈荫',
  ['os__protect'] = '荫',
  ['#os__ciyin-ask'] = '你可选择一名其他角色成为你的 慈荫 同心角色',
  ['#os__ciyin-get'] = '慈荫：将任意张♠或<font color=>♥</font>牌置于你的武将牌上，称为“荫”，将其余牌置于牌堆顶',
  ['os__ciyin_recover'] = '加1点体力上限并回复1点体力',
  ['os__ciyin_draw'] = '将手牌摸至体力上限',
  ['#os__ciyin_only-choose'] = '慈荫：选择一项同心效果，仅你执行',
  ['#os__ciyin-choose'] = '慈荫：选择一项同心效果，你和 %dest 执行',
  ['@os__ciyin'] = '慈荫同心',
  [':os__ciyin'] = '你或<a href=>同心角色</a>的准备阶段，你可亮出牌堆顶的X张牌（X为当前回合角色体力值的两倍且至多为10），将其中任意张♠或<font color=>♥</font>牌置于你的武将牌上，称为“荫”，然后将其余牌置于牌堆顶。你每获得三张“荫”，须执行一项本局游戏未执行过的<a href=>同心效果</a>：1.加1点体力上限并回复1点体力；2.将手牌摸至体力上限。',
  ['$os__ciyin1'] = '虽为纤弱之身，亦当为吾儿遮风挡雨。',
  ['$os__ciyin2'] = '纵有狼虎于前，定保吾儿平安。',
}

os__ciyin:addEffect(fk.EventPhaseStart, {
  derived_piles = "os__protect",
  can_trigger = function (self, event, target, player, data)
    return target.phase == Player.Start and (target == player or target.id == player:getMark("_os__ciyin"))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target.phase == Player.Start then
      local num = math.min(10, target.hp * 2)
      local cards = room:getNCards(num)
      room:moveCards{
        ids = cards,
        toArea = Card.Processing,
        moveReason = fk.ReasonJustMove,
        skillName = os__ciyin.name,
        proposer = player.id,
      }

      local cardmap = room:askToArrangeCards(player, {
        piles = {cards, "Top", "os__protect"},
        title = "#os__ciyin-get",
        box_size = 0,
        pattern = ".|.|heart,spade"
      })
      if #cardmap[2] > 0 then
        player:addToPile("os__protect", cardmap[2], true, os__ciyin.name, player.id)
      end
      if #cardmap[1] > 0 then
        room:moveCards{
          ids = table.reverse(cardmap[1]),
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = os__ciyin.name,
          moveVisible = false,
        }
      end

      if player.dead then return end
      local choices = {"os__ciyin_recover", "os__ciyin_draw"}
      local tongxin_choice = {}
      local companion = player:getMark("_os__ciyin") ---@type integer
      if #player:getPile("os__protect") >= 3 and player:getMark("_os__ciyin_choice") == 0 then
        local choice = room:askToChoice(player, {
          choices = choices,
          skill_name = os__ciyin.name,
          prompt = companion == 0 and "#os__ciyin_only-choose" or "#os__ciyin-choose::" .. companion
        })
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
                skillName = os__ciyin.name
              }
            end
          end
          if table.contains(tongxin_choice, "os__ciyin_draw") and p.maxHp > p:getHandcardNum() then
            p:drawCards(p.maxHp - p:getHandcardNum(), os__ciyin.name)
          end
        end
      end
    end
  end,
})

os__ciyin:addEffect(fk.TurnStart, {
  can_trigger = function (self, event, target, player, data)
    return target == player
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os__ciyin-ask",
      skill_name = os__ciyin.name
    })
    if #targets > 0 then
      event:setCostData(self, {tos = targets})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:setPlayerMark(player, "@os__ciyin", room:getPlayerById(to).general)
    room:setPlayerMark(player, "_os__ciyin", to)
  end,
})

os__ciyin:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__ciyin") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    room:setPlayerMark(player, "_os__ciyin", 0)
    room:setPlayerMark(player, "@os__ciyin", 0)
  end,
})

return os__ciyin
