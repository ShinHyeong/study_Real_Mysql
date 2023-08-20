9.3.1.3 인덱스 컨디션 푸시다운
SELECT * FROM employee WHERE last_name = 'Acton' AND first_name LIKE '%sal';

-> last_name = 'Acton' 으로 인덱스 레인지 스캔하여 테이블의 레코드를 읽은 후, first_name LIKE '%sal' 조건에 부합하는지 여부를 비교하는 과정


9.3.1.6 인덱스 머지 - 교집합
select * from employees where first_name='George' and emp_no between 10000 and 20000;


9.3.1.7 인덱스 머지 - 합집합
select * from employees where first_name='Matt' or hire_date='2022-07-13';


9.3.1.8 인덱스 머지 - 정렬 후 합집합
- 위의 Union 알고리즘에서 정렬된 결과로 중복제거를 하는데 정렬이 이미 되어있으므로 필요하지 않음.
- 하지만 도중에 정렬이 필요한 경우에는 Sort union 알고리즘을 사용한다.

9.3.1.9 세미 조인
- 다른 테이블과 실제 조인을 수행하지는 않고, 
단지 다른 테이블에서 조건에 일치하는 레코드가 있는지 없는지만 체크하는 형태의 쿼리를 세미 조인이라 한다.

9.3.1.13 구체화(Materialization)
Mataerialization 최적화는 세미 조인에 사용된 서브쿼리를 통째로 구체화해서 쿼리를 최적화한다.

9.3.1.14 중복 제거(Duplicated Weed-out)

9.3.1.15 컨디션 팬아웃(condition_fanout_filter)
- 조인을 실행할 때 테이블의 순서는 쿼리의 성능에 매우 큰 영향을 미친다.
    MySQL 옵티마이저는 여러 테이블이 조인되는 경우 가능하다면 일치하는 레코드 건수가 적은 순서대로 조인을 실행한다.

- 실행계획에는 쿼리 실행시 읽게 될 rows의 갯수와 실행 결과 rows의 비율인 filtered 칼럼이 있다.
    rows * filtered / 100 이 쿼리 실행 결과 나오게 될 rows 수이다.




