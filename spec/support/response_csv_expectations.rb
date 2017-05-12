module ResponseCSVExpectations
  def response_csv_expectation_without_repeat_groups(uuids, shortcodes)
    return ("Form,Submitter,DateSubmitted,ResponseUUID,ResponseShortcode,TextQ1,SelectOneQ2:Country,SelectOneQ2:City,SelectOneQ2:Latitude,SelectOneQ2:Longitude,LongTextQ3,IntegerQ4,DecimalQ5,LocationQ6:Latitude,LocationQ6:Longitude,SelectOneQ7,SelectOneQ8,SelectOneQ9,SelectMultipleQ10,DatetimeQ11,DateQ12,TimeQ13,TextQ14,LongTextQ15,SelectOneQ16,SelectOneQ16:Latitude,SelectOneQ16:Longitude\r
Sample Form 1,A User 2,2015-11-20 06:20 CST,#{uuids[0]},#{shortcodes[0]},alpha,Ghana,Tamale,9.4075,0.8533,bravo,80,1.23,,,,Dog,,Cat,2015-01-12 03:15 CST,2014-02-03,03:43\r
Sample Form 1,A User 1,2015-11-20 06:30 CST,#{uuids[1]},#{shortcodes[1]},foo✓,Canada,Calgary,51.045,-114.057222,\"foo\r
\r
\"\"bar\"\"  \r\nbaz\",100,-123.5,15.937378,44.36453,Cat,Dog,Cat,Dog;Cat,2015-10-12 12:15 CST,2014-11-09,23:15\r
Sample Form 1,A User 3,2015-11-20 06:30 CST,#{uuids[2]},#{shortcodes[2]},foo,Canada,,,,bar,100,-123.5,15.937378,44.36453,Cat,Dog,Cat,Dog;Cat,2015-10-12 12:15 CST,2014-11-09,23:15\r
Sample Form 1,A User 4,2015-11-20 06:30 CST,#{uuids[3]},#{shortcodes[3]},foo,Ghana,,7.1,0.4,bar,100,-123.5,15.937378,44.36453,Cat,Dog,Cat,Dog;Cat,2015-10-12 12:15 CST,2014-11-09,23:15\r
Sample Form 2,A User 5,2015-11-20 06:30 CST,#{uuids[4]},#{shortcodes[4]},,Ghana,Accra,5.55,0.2,,,,,,,,,,,,,foo,bar,Funton,-12.9,22.7\r\n")
  end

  def response_csv_expectation_with_repeat_groups(uuids, shortcodes)
    return ("Form,Submitter,DateSubmitted,ResponseUUID,ResponseShortcode,GroupName,GroupLevel,IntegerQ1,Fruit:TextQ2,Fruit:IntegerQ3,Fruit:SelectMultipleQ4,IntegerQ5,Vegetable:TextQ6,Vegetable:SelectOneQ7:Country,Vegetable:SelectOneQ7:City,Vegetable:SelectOneQ7:Latitude,Vegetable:SelectOneQ7:Longitude,Vegetable:IntegerQ8\r
Sample Form 1,A User 1,2015-11-20 06:30 CST,#{uuids[0]},#{shortcodes[0]},,0,1,,,,2,,,,,,\r
Sample Form 1,A User 1,2015-11-20 06:30 CST,#{uuids[0]},#{shortcodes[0]},Fruit,1,1,Apple,1,Cat;Dog,2,,,,,,\r
Sample Form 1,A User 1,2015-11-20 06:30 CST,#{uuids[0]},#{shortcodes[0]},Fruit,1,1,Banana,2,Cat,2,,,,,,\r
Sample Form 1,A User 1,2015-11-20 06:30 CST,#{uuids[0]},#{shortcodes[0]},Vegetable,1,1,,,,2,Asparagus,Ghana,Accra,5.55,0.2,3\r
Sample Form 1,A User 2,2015-11-20 06:30 CST,#{uuids[1]},#{shortcodes[1]},,0,3,,,,4,,,,,,\r
Sample Form 1,A User 2,2015-11-20 06:30 CST,#{uuids[1]},#{shortcodes[1]},Fruit,1,3,Xigua,10,Dog,4,,,,,,\r
Sample Form 1,A User 2,2015-11-20 06:30 CST,#{uuids[1]},#{shortcodes[1]},Fruit,1,3,Yuzu,9,Cat;Dog,4,,,,,,\r
Sample Form 1,A User 2,2015-11-20 06:30 CST,#{uuids[1]},#{shortcodes[1]},Fruit,1,3,Ugli,8,Cat,4,,,,,,\r
Sample Form 1,A User 2,2015-11-20 06:30 CST,#{uuids[1]},#{shortcodes[1]},Vegetable,1,3,,,,4,Zucchini,Canada,Calgary,51.045,-114.057222,7\r
Sample Form 1,A User 2,2015-11-20 06:30 CST,#{uuids[1]},#{shortcodes[1]},Vegetable,1,3,,,,4,Yam,Canada,Ottawa,45.429299,-75.629883,6\r\n")
  end
end
