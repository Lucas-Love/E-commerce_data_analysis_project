__数据处理和数据清洗：
__新建数据列：
alter table userbehavior add datetime datetime;
alter table userbehavior add b_date varchar(255);
alter table userbehavior add b_time varchar(255);
__更新前1000000行数据,并且转换格式：
update userbehavior set b_datetime=from_unixtime(time) limit 1000000;
update userbehavior set b_date=mid(b_datetime,1,10) limit 1000000;
update userbehavior set b_time=right(b_datetime,8) limit 1000000;
__删除1000000行之后的数据：
delete from userbehavior where b_datetime is null;
__获取指定日期的数据：
delete from userbehavior where b_date<'2017-11-25' or b_date>'2017-12-03';
__验证数据：
select max(b_date) as '日期上限',
	   min(b_date) as '日期下限'
from userbehavior;
__缺失值检查：
select count(user_id),count(item_id),count(category),count(bahavior),count(time),count(b_datetime),count(b_date),count(b_time)
from userbehavior
__重复行检查：
select user_id,item_id,category,behavior,time,b_datetime,b_date,b_time
from userbehavior
group by user_id,item_id,category,behavior,time,b_datetime,b_date,b_time
having count(*)>1;
__UV,PV,用户平均访问量
select count(distinct user_id) as UV,
	   sum(case when behavior='pv' then 1 else 0 end) as PV,
	   round(sum(case when behavior='pv' then 1 else 0 end)/count(distinct user_id),2) as '用户平均访问量'
from userbehavior;
__用户跳出率：
__用户行为随日期变化：
select b_date as '日期',
	   count(distinct user_id) as '每日用户访客数',
	   sum(case when behavior='pv' then 1 else 0 end) as '每日用户点击量',
	   sum(case when behavior='fav' then 1 else 0 end) as '每日用户收藏次数',
	   sum(case when behavior='cart' then 1 else 0 end) as '每日用户加入购物车次数',
	   sum(case when behavior='buy' then 1 else 0 end) as '每日用户购买次数'
from userbehavior
group by b_date;
__用户行为随时间变化：
select mid(b_time,1,2) as '时间',
	   count(distinct user_id) as '每时用户访客数',
	   sum(case when behavior='pv' then 1 else 0 end) as '每时用户点击量',
	   sum(case when behavior='fav' then 1 else 0 end) as '每时用户收藏次数',
	   sum(case when behavior='cart' then 1 else 0 end) as '每时用户加入购物车次数',
	   sum(case when behavior='buy' then 1 else 0 end) as '每时用户购买次数'
from userbehavior
group by b_time;
__top10 热销产品：
select item_id as '商品编号',category as '商品种类', count(behavior) as '销量'
from userbehavior
where behavior='buy'
group by item_id
order by count(behavior) desc
limit 10;
__top10 热门产品：
select item_id as '商品编号',category as '商品种类', count(behavior) as '点击量'
from userbehavior
where behavior='pv'
group by item_id
order by count(behavior) desc
limit 10;
__top10 心动产品：
select item_id as '商品编号',category as '商品种类', count(behavior) as '收藏量'
from userbehavior
where behavior='fav'
group by item_id
order by count(behavior) desc
limit 10;
__top10点击产品（热门产品）的购买量：
select a.item_id,a.点击量,
			 sum(case when behavior='buy' then 1 else 0 end) as 购买量
from
(
select item_id ,category as '商品种类', count(behavior) as '点击量'
from userbehavior
where behavior='pv'
group by item_id
order by count(behavior) desc
limit 10) as a 
inner join  userbehavior as u
on a.item_id=u.item_id
group by a.item_id
__top10 热销产品种类：
select category as '商品种类', count(behavior) as '销量'
from userbehavior
where behavior='buy'
group by category
order by count(behavior) desc
limit 10;
__top10 热门产品种类：
select category as '商品种类', count(behavior) as '点击次数'
from userbehavior
where behavior='pv'
group by category
order by count(behavior) desc
limit 10;
__人均购买次数：
select sum(case when behavior='buy' then 1 else 0 end) as '订单量',
	   count(distinct user_id) as '用户数',
	   sum(case when behavior='buy' then 1 else 0 end)/count(distinct user_id) as '人均购买次数'
from userbehavior;
__购买两次及以上的用户数：
select count('购买过两次以上的用户') as '购买过两次以上的用户数'
from
(
select user_id as '购买过两次以上的用户数'
from userbehavior
where behavior='buy'
group by user_id
having count(*)>=2) as a
__复购率：
__经常消费的重点客户：
select user_id,count(user_id) as '用户购买次数'
from userbehavior
where behavior='buy'
group by user_id
order by count(user_id) desc
limit 10;
__用户行为转化：
select behavior as '用户行为', count(behavior) as '用户行为数量'
from userbahavior
group by behavior
order by count(behavior) desc;
__用户转化路径1：点击-收藏-购买
select count(distinct a.user_id) as '点击数',
	   count(distinct b.user_id) as '收藏数',
	   count(distinct c.user_id) as '购买数'
from 
(
(select user_id,item_id,category,time from userbehavior where behavior='pv') as a
left join 
(select user_id,item_id,category,time from userbehavior where behavior='fav') as b
on (a.user_id=b.user_id and a.item_id=b.item_id and a.category=b.category and a.time<b.time)
left join 
(select user_id,item_id,category,time from userbehavior where behavior='buy') as c
on (b.user_id=c.user_id and b.item_id=c.item_id and b.category=c.category and b.time<c.time)
)
__用户转化路径2：点击-加入购物车-购买
select count(distinct a.user_id) as '点击数',
	   count(distinct b.user_id) as '加入购物车数',
	   count(distinct c.user_id) as '购买数'
from 
(
(select user_id,item_id,category,time from userbehavior where behavior='pv') as a
left join 
(select user_id,item_id,category,time from userbehavior where behavior='cart') as b
on (a.user_id=b.user_id and a.item_id=b.item_id and a.category=b.category and a.time<b.time)
left join 
(select user_id,item_id,category,time from userbehavior where behavior='buy') as c
on (b.user_id=c.user_id and b.item_id=c.item_id and b.category=c.category and b.time<c.time)
)
__各字段的数量：
select count(distinct user_id) as '用户数',
			 count(distinct item_id) as '商品数',
			 count(distinct category) as '商品类别数',
			 count(distinct behavior) as '用户行为数量'
from userbehavior;
__点击量前十的商品购买率：
select item_id as '商品编号',
			 category as '商品种类',
			 sum(case when behavior='pv' then 1 else 0 end) as '点击量',
			 sum(case when behavior='buy' then 1 else 0 end) as '购买量',
			 concat((sum(case when behavior='buy' then 1 else 0 end)/sum(case when behavior='pv' then 1 else 0 end))*100,'%') as '购买率'
from userbehavior
group by item_id
order by count(behavior) desc
limit 10;
__RFM打分：
__最近一次购买间隔视图创建：
create view Time_interval as 
select user_id,datediff('2017-12-03',max(b_date)) as '最近一次购买间隔'
from userbehavior
where behavior='buy'
group by user_id
__R:
create view score_R as 
select user_id ,
(
case when `最近一次购买间隔` between 0 and 2 then 4
	 when `最近一次购买间隔` between 3 and 4 then 3
     when `最近一次购买间隔` between 5 and 6 then 2
	 when `最近一次购买间隔` between 7 and 8 then 1
	 else 0
	 end
) as 'R'
from Time_interval;
__每个用户购买次数视图：
create view Purchases_number as 
select user_id,count(behavior) as '购买次数'
from userbehavior
where behavior='buy'
group by user_id
__最大，最小购买次数：
select 
min(`购买次数`) as '最小购买次数',
max(`购买次数`) as '最大购买次数'
from purchases_number;
__F:
create view score_f as 
select user_id,
       (
			 case when 购买次数 between 1 and 18 then 1
						when 购买次数 between 19 and 36 then 2
					  when 购买次数 between 37 and 54 then 3
				    when 购买次数 between 55 and 72 then 4	
				else 0
				end						
			 ) as 'F'
from purchases_number
order by F desc;
__求R的平均分：
select avg(R) AS R平均
from score_r;
__求F的平均分：
select avg(F) AS F平均
from score_f;
__创建RF 视图：
create view RF AS 
select a.user_id,R,F
from 
(
score_f as a inner join score_r as b
on a.user_id=b.user_id
)
__最终用户分类：
create view users_classification as 
select user_id,
			 (
			 case when R>3 and F>1 then '重要价值用户'
			      when R>3 and F<=1 then '重要保持用户'
			      when R<=3 and F>1 then '重要发展用户'
			      when R<=3 and F<=1 then '一般价值用户'
			 else 0
			 end) as '用户分类'
from rf;
__各种类用户数：
select count(用户分类) as 重要价值用户 from users_classification where 用户分类='重要价值用户';
select count(用户分类) as 重要保持用户 from users_classification where 用户分类='重要保持用户';
select count(用户分类) as 重要发展用户 from users_classification where 用户分类='重要发展用户';
select count(用户分类) as 一般价值用户 from users_classification where 用户分类='一般价值用户';

