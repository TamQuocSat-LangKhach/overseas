local os__kaizeng = fk.CreateSkill {
  name = "os__kaizeng"
}

Fk:loadTranslationTable{
  ['os__kaizeng'] = '慨赠',
  ['os__kaizeng_others&'] = '慨赠',
  [':os__kaizeng'] = '其他角色的出牌阶段限一次，其可秘密指定一种基本牌牌名或非基本牌类别，令你选择是否交给其任意张手牌。若你交给其多于一张牌，你摸一张牌；若其中包含其指定的牌名/类别的牌，你从牌堆中获得一张不同牌名/类别的牌。',
  ['$os__kaizeng1'] = '此心唯念天下之士，不较细软锱铢！',
  ['$os__kaizeng2'] = '千金散尽何须虑，但求天下俱欢颜！'
}

os__kaizeng:addEffect(fk.TargetRequested, {
  attached_skill_name = "os__kaizeng_others&",
})

return os__kaizeng
