# 10.3 실행 계획 분석
- 옵션 없이 EXPLAIN 명령을 실행하면 쿼리에 따라 표 형태로 1줄 이상의 결과가 표시된다.
    - 표의 각 라인은 쿼리에서 사용된 테이블(서브쿼리로 임시 테이블을 생성한 경우 그 임시테이블 포함)의 개수만큼 출력된다.
    - 실행 순서는 위에서 아래로 순서대로 표시된다. (UNION, 상관 서브쿼리의 경우 순서대로 표시되지 않을 수 있다.)
    - 출력된 실행계획에서 위쪽에 출력된 결과일수록 먼저 접근한 테이블이고 아래쪽에 출력된 결과는 나중에 접근한 테이블에 해당된다.

![explain 출력화면](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*ef1av-7mRsPGX_gbCKhHjg.png)

#### 10.3.1 id 컬럼

- `SELECT` 문장은 다시 1개 이상의 하위(sub) SELECT 문장을 포함할 수 있다.

  ```sql
    SELECT * FROM (SELECT * FROM test1) t1, test2 t2 where..
  ```

  - 위 쿼리의 SELECT 키워드 단위로 구분한 것을 앞으로 단위 쿼리라고 표현한다.
- 실행 계획의 id 컬럼은 단위 SELECT 쿼리별로 부여되는 식별자 값이다.
- 만약 테이블을 조인하면, 테이블의 개수만큼 실행계획 레코드가 출력되지만 같은 id 값이 부여된다.
- 반대로 다음 쿼리의 실행 계획에서는 쿼리 문장의 3개의 단위 SELECT 쿼리로 구성돼 있으므로 실행계획의 각 레코드가 다른 id 값을 가지게 된다.

  ```sql
    EXPLAIN SELECT (( SELECT count(*) FROM user) + (SELECT count(*) FROM boss) ) as total;
  ```

- 한 가지 중요한 것은 실행 계획의 Id 컬럼이 테이블의 접근 순서를 의미하지는 않는다.

#### 10.3.2 select_type

- 각 단위 SELECT가 어떤 타입의 쿼리인지 표시되는 컬럼이다. 표시될 수 있는 값은 아래와 같다.
  - **SIMPLE**
    - **UNION이나 서브쿼리를 사용하지 않는** 단순한 SELECT 쿼리는 SIMPLE로 표현된다.
    - 쿼리가 아무리 복잡하더라도 SIMPLE인 단위 쿼리는 하나만 존재한다.
  - **PRIMARY**
    - **UNION이나 서브쿼리를 사용하는** SELECT 쿼리의 가장 바깥쪽에 있는 단일 쿼리는 PRIMARY로 표시된다.
    - 마찬가지로 PRIMARY인 단위 쿼리는 하나만 존재한다.
  - **UNION**
    - UNION으로 결합하는 단위 SELECT 쿼리 중 **두 번째 이후 단위 SELECT 쿼리**는 UNION으로 표시된다.
    - UNION의 첫번째 단위 SELECT는 쿼리 결과들을 모아 저장하는 임시테이블(DERIVED)이 된다.
  - **DEPENDENT UNION**
    - DEPENDENT는 UNION, UNION ALL로 결합한 단위 쿼리가 외부 쿼리에 의해 영향을 받는 것을 의미한다.
    - 내부 쿼리가 외부의 값을 참조해서 처리될 때 DEPENDENT 키워드가 표시된다.
  - **UNION RESULT**
    - UNION 결과를 담아두는 테이블을 의미한다. 실제 쿼리가 아니기 때문에 id 값이 부여되지 않는다.
  - **SUBQUERY**
    - FROM 절 외에서 사용되는 서브쿼리(ex: select)를 의미한다.
    - FROM 절에 사용된 서브쿼리는 DERIVED로 표시되고 그 밖의 위치에서 사용된 서브쿼리는 SUBQUERY로 표시된다.
  - **DEPENDENT SUBQUERY**
    - 서브쿼리가 SELECT 쿼리에서 정의된 컬럼을 사용하는 경우 표시된다.
  - **DERIVED**
    - MySQL 5.5 버전까지는 FROM 절에 서브쿼리가 사용된 경우 항상 DERIVED로 표시되지만 5.6 버전부터 최적화가 수행되기도 한다.
    - DERIVED는 단위 쿼리의 실행결과로 메모리나 디스크에 임시 테이블을 생성하는 것을 의미한다.
  - **DEPENDENT DERIVED**
    - MySQL 8.0 이전에서는 FROM 절의 서브쿼리는 외부 컬럼을 사용할 수 없었는데 8.0 버전부터 `레터럴 조인(LATERAL JOIN)` 기능이 추가되면서 FROM 절의 서브쿼리가 외부 컬럼을 사용하면 표시된다.
  - **UNCACHEABLE SUBQUERY**
    - 하나의 쿼리에 서브쿼리가 하나만 있더라도 그 서브쿼리가 한 번만 실행되는 건 아니다.
    - 조건이 똑같은 서브쿼리가 실행될 때, 서브쿼리 결과를 캐시 공간에 담을 수 있다.
    - `UNCACHEABLE SUBQUERY`는 서브쿼리에 포함된 요소에 의해 캐시를 사용하지 못할 경우 표시된다.
  - **UNCACHEABLE UNION**
    - 캐시를 사용하지 못하는 UNION
  - **MATERIALIZED**
    - MySQL 5.6 버전부터 도입된 타입으로 주로 `FROM, IN` 쿼리 다음에 사용된 서브쿼리의 최적화를 위해 사용된다.
    - MySQL 5.7 버전부터는 서브쿼리의 내용을 임시 테이블로 `구체화(MATERIALIZED는)` 한 뒤, 원본 테이블과 조인하는 형태로 최적화되어 처리된다.

#### 10.3.3 table

- MySQL 서버의 실행계획은 `SELECT` 쿼리 기준이 아니라 **테이블 기준**으로 표시된다.
- 테이블 이름에 별칭이 부여된 경우 별칭이 표시된다.

```text
id | select_type | table     |
------------------------------
1  | PRIMARY     |<derived2> |
1  | PRIMARY     | e         |
2  | DERIVED     | de        |
```

- 위의 실행 계획을 분석해보자
  - 첫번째 라인의 table이 `derived2`이면 id가 2인 라인이 먼저 실행되고 그 결과가 파생 테이블로 준비돼어야 한다.
  - 세번째 라인은 조회하는 테이블을 읽어서 파생 테이블을 생성한다.
  - 첫번째, 두번째 라인은 id가 동일한 걸봐서 조인되는 쿼리인걸 알 수 있다. 그런데 `derived2`가 e보다 위에 있기 때문에
    derived2가 드라이빙 테이블이 되고 e 테이블이 드리븐 테이블이 된다. 즉 `derived2` 테이블을 먼저 읽고 e 테이블을 조인했다.

#### 10.4.4 partitions

- **MySQL 5.7** 버전까지는 옵티마이저가 사용하는 파티션 목록을 `EXPLAIN PARTITON` 명령을 이용해 확인했다.
- **MySQL 8.0** 버전부터는 `EXPLAIN` 명령으로 파티션 관련 계획까지 확인할 수 있다.

```sql
create table `tb_range_table` (
  id int not null,
  name varchar(10),
  dept varchar(10),
  hire_date date not null default '2010-01-01'
) engine=innodb default charset=utf8mb4
partition by range(year(hire_date)) (
partition p0 values less than(2011) engine=innodb,
partition p1 values less than(2012) engine=innodb,
partition p2 values less than(2013) engine=innodb,
partition p3 values less than(2014) engine=innodb,
partition p999 values less than maxvalue engine=innodb);

SELECT * FROM tb_range_table WHERE hire_date BETWEEN '2012-01-01' AND '2013-12-31';
```

- 범위 조건을 보면 p1, p2 파티션에 저장된 것을 알 수 있다.
- 옵티마이저는 쿼리의 조건을 보고 필요한 데이터가 p1, p2에 있다는 것을 알아낼 수 있다. 이처럼 파티션을 골라내는
과정을 `파티션 프루닝(Partition Prunning)` 이라고 부른다.
- 아래 type을 보면 풀테이블 스캔이 발생하는데, 정확히는 p1, p2에 대해서만 풀 스캔을 실행한다.

```text
id | select_type | table          | partitons | type |
-----------------------------------------------------
1  | SIMPLE      | tb_range_table | p1, p2    | ALL  |
```

#### 10.3.5 type

- 실행계획에서 **type 이후의 컬럼은** 테이블의 레코드를 어떤 방식으로 읽었는지를 나타낸다.
- type은 **테이블의 접근 방법**을 의미하고, 쿼리 튜닝시 인덱스를 어떻게 사용하는지 확인하는게 중요하므로 type 컬럼은 중요하다.
- type 컬럼의 값으로는 아래와 같은 값이 올 수 있다.
  - system, const, eq_ref, ref, fulltext, ref_or_null, unique_subquery, index_subquery, ragne, index
  - index_merge
  - ALL
- ALL은 풀테이블 스캔 접근 방법을 의미하며 **나머지는 인덱스를 사용**하는 접근 방법이다.
- `index_merge를` 제외한 접근 방법은 하나의 인덱스만 사용한다.
- **system**
  - 레코드가 없거나 1건만 존재하는 테이블을 참조하는 형태
  - InnoDB는 나타나지 않고 MyISAM or MEMORY 테이블에서만 사용된다.
- **const**
  - PK나 유니크 컬럼으로 조회해서 1건이 나올 떄 처리방식을 const라고 부른다.
  - `SELECT * FROM team WHERE id = 1;`
- **eq_ref**
  - 조인 쿼리에서 나타나며, 조인에서 처음 읽은 테이블(드라이빙)의 컬럼을 그 다음 읽어야 할 테이블(드리븐)의 PK or 유니크 키 조건으로 사용할 때 eq_ref로 표시된다.
  - `SELECT * FROM team_user, user WHERE team_user.user_id = user.id AND team_user.team_id = 3`
- **ref**
  - `eq_ref`와 달리 조인 순서랑 관계가 없으며, ref는 레코드가 1건이라는 보장이 없어 `const, eq_ref` 보다는 느리다.
  - 하지만 동등 조건이기에 빠른 조회 방법 중 하나다.
  - `SELECT * FROM user WHERE id = 3`
- 위 3가지 방법`(const, eq_ref, ref)`은 성능상에 문제가 없어 넘어가도 무방하다.
- **full_text**
  - MySQL 서버의 전문 검색 인덱스를 사용해 레코드를 읽는 접근 방법
  - 전문 검색 조건은 우선순위가 높아서 `const, eq_ref, ref`가 아니라면 전문 인덱스를 선택한다.
  - 하지만 저자의 경험상 `range`가 빨리 처리되는 경우가 많아 전문 검색 쿼리 사용시에는 성능을 확인하는게 좋다.
- **ref_or_null**
  - ref + null 비교
- **unique_subquery**
  - where 절에 IN 형태의 쿼리를 위한 접근방법으로 중복되지 않은 유니크를 반환할 때 사용된다.
- **index_subquery**
  - 서브쿼리 결과의 중복된 값을 인덱스를 이용해 제거할 수 있을 때 사용된다.
- **range**
  - index range 스캔 형태의 접근 방법이다. 주로 범위로 검색하는 경우 사용된다.
  - range 접근 방법도 상당히 빠른편에 속한다.
- **index_merge**
  - 2개 이상의 인덱스를 병합해서 처리하는 방식
  - 여러 인덱스를 읽어야 하므로 range 보다 효율성이 떨어지고 전문 검색 인덱스를 사용하는 곳에서는 적용되지 않는다.
  - Extra 컬럼에 부가적인 내용이 표시됨
- **index**
  - 인덱스 풀 스캔을 의미하며, 풀 테이블 스캔보다 훨씬 빠르고 효율적이다.
  - `SELECT * FROM user ORDER BY index_key LIMIT 10`
  - LIMIT 조건이 없거나 가져오는 레코드 건수가 많으면 느리다.
- **ALL**
  - 풀 테이블 스캔으로 위에서 설명한 방식으로 처리할 수 없을때 마지막으로 선택된다.

#### 10.3.6 possible_keys

- 사용될뻔 했던 인덱스 목록이 표시되며 튜닝에 도움이 되지 않으므로 무시

#### 10.3.7 key

- **실행된 인덱스**를 의미한다.
- `PRIMARY로` 표시될 경우 PK가 사용되었다는 의미이며 그 외에는 인덱스의 고유이름이 표기된다.
- 실행 계획의 type이 ALL인 경우 key 컬럼은 NULL로 표시된다.

#### 10.3.8 key_len

- 인덱스의 레코드에서 **몇 바이트를 사용**했는지 알려주는 값이다.
- PK로 (team_id, user_id) 가지는 team_user 테이블이 있다고 가정하자.

```sql
EXPLAIN SELECT * FROM team_user WHERE team_id = 't001';

id | select_type | table     | key     | key_len |
--------------------------------------------------
1  | SIMPLE      | team_user | PRIMARY | 16      |
```

- team_id 타입이 char(4)이기 때문에 PK의 앞쪽 16 바이트만 유효하게 사용했다는 의미.
- team_id 컬럼은 utf8mb4 문자 집합을 사용한다. MySQL 서버가 utf8mb4 문자를 위해 메모리를 할당할 때 고정적으로 4 바이트로 계산한다. 그래서 위의 실행 계획해서 key_len 값이 16 바이트 (4 * 4)가 표시된 것이다.

```sql
EXPLAIN SELECT * FROM team_user WHERE team_id = 't001' AND user_id = 1;

id | select_type | table     | key     | key_len |
--------------------------------------------------
1  | SIMPLE      | team_user | PRIMARY | 20      |
```

- user_id는 정수로 4 바이트를 차지한다. 따라서 key_len 값은 16 + 4로 20바이트를 사용한다.

```sql
 EXPLAIN SELECT * FROM titles WHERE to_date <= '1988-01-01';

id | select_type | table     | key        | key_len |
--------------------------------------------------
1  | SIMPLE      | titles    | idx_todate | 4       |
```

- MySQL에서 Date 타입은 3 바이트지만 nullable한 컬럼의 경우 NULL인지 아닌지 저장하기 위해 1 바이트를 더 사용한다.

#### 10.3.9 ref 컬럼

- type 값(접근 방법)이 ref 방식일 경우, equal 비교 조건으로 어떤 값이 제공됐는지 보여준다.
- 상수 값이면 const로 표시되고, 다른 테이블의 컬럼값이면 테이블명과 컬럼값이 표시된다.

```sql
EXPLAIN SELECT * FROM user u, team_user tu
WHERE u.id = tu.user_id;

id | select_type | table | type   | ref            |
----------------------------------------------------
1  | SIMPLE      | tu    | ALL    | NULL           |
1  | SIMPLE      | u     | eq_ref | user.tu.user_id|
```

#### 10.3.10 rows

- 실제 반환하는 레코드 예측치가 아니라, 쿼리를 처리하기 위해 얼마나 많은 레코드를 읽고 체크해야 하는지를 의미한다.
- rows에 출력되는 값과 실제 쿼리 결과로 반환된 레코드 건수가 일치하지 않는 경우가 많다.

#### 10.3.11 filtered

- 필터링되어 버려지는 레코드 비율이 아니라, 조건절에서 **필터링 되고 남은 레코드의 비율**을 의미한다.

```sql
EXPLAIN SELECT * FROM user u, team_user tu
WHERE use_index_condition_A and no_index_condition_B;

id | select_type | table | type | rows | filtered |
----------------------------------------------------
1  | SIMPLE      | tu    | ref  | 233  |16.03     |
1  | SIMPLE      | u     | ref  | 10   |0.48      |
```

- 인덱스 A 조건에 일치하는 레코드는 대충 233건, 이 중에서 16.03%가 B 조건에 일치
- 233건 중에 16.03 퍼센트가 필터링 되어 남으니 대충 37건이 반환될 것을 의미한다.

#### 10.3.12 Extra 컬럼

- 쿼리 실행 계획 중 성능에 관련된 중요한 내용이 Extra 컬럼에 자주 표시된다. Extra 컬럼에는 내부적인 처리
알고리즘에 대해 깊이 있는 내용을 보여주는 경우가 많다.
- **const row not found**
  - 쿼리 실행계획에서 const 접근 방법으로 테이블을 읽었지만 실제로 해당 테이블에 레코드가 1건도 존재하지 않으면 표시된다.
- **Deleting all rows**
  - where 조건절이 없는 DELETE 문장의 실행계획에서 자주 표시되며, 쿼리를 한 번 호출하여 모든 레코드를 삭제했다는 의미이다.
- **impossible having**
  - 쿼리에 사용된 Having 절의 조건을 만족하는 레코드가 없을 때 실행 계획의 Extra 컬럼에 표시된다.
- **impossible where**
  - where 조건이 항상 false가 될 수 밖에 없는 경우 표시된다.
- **LooseScan**
  - 세미 조인 최적화 중에서 LooseScan 최적화 전략이 사용되면 표시된다.
- **No matching min/max row**
  - min, max 같은 집합 함수가 있는 쿼리의 조건절에 일치하는 레코드가 없을 때 표시된다.
- **no matching row in const table**
  - 조인에 사용된 테이블에서 const 방법으로 접근할 때 일치하는 레코드가 없다면 표시된다.
- **no matching rows after partition pruning**
  - 파티션에서 update하거나 delete 할 대상 레코드가 없을 때 표시된다.
- **not exists**
  - 개발하다 보면 A 테이블에는 있지만 B 테이블에 없는 값을 조회해야 하는 쿼리가 사용된다. 주로 not in, not exist 형태를 사용하는데 이러한 형태를 안티 조인이라고 한다.
  - 똑같은 조인을 outer 조인을 이용해서 구현할 수 있다. 레코드 건수가 많을 때는 아우터 조인을 이용하면 빠른 성능을 낼 수 있다.
  - 이렇게 아우터 조인을 이용해 안티 조인을 수행하는 쿼리에서는 실행 계획의 extra 컬럼에 표시된다.
- **recursive**
  - MySQL 8.0 버전부터 CTE(Common Table Expression)를 이용해 재귀 쿼리를 작성할 수 있는데 이 경우 표시된다.
- **Rematerialize**
  - MySQL 8.0 버전부터 래터럴 조인 기능이 추가됐는데, 래터럴로 조인되는 테이블은 선행 테이블의 레코드별로 서브 쿼리를 실행해서 그 결과를 임시 테이블에 저장한다. 이 과정을 rematerializing 이라고 한다.
- **Select tables optimized away**
  - MIN, MAX만 SELECT 절에 사용되거나 GROUP BY로 MIN, MAX를 조회하는 쿼리가 인덱스를 오름차순/내림차순으로 1건만 읽는 형태의 최적화가 적용되면 표시된다.
- **Start temporary, End temporary**
  - 세미 조인 최적화 중에서 Duplicate Weed-out 최적화 전략이 사용되면 표시된다.
- **Using filesort**
  - order by 처리가 인덱스를 사용하지 못할 때만 표시되며, 정렬용 메모리 버퍼에 복사해 퀵 소트 or 힙 소트 알고리즘을 이용해 정렬을 수행하게 된다는 의미다. 이 실행계획은 order by가 사용된 쿼리에만 나타난다.
- **Using index (커버링 인덱스)**
  - 데이터 파일을 전혀 읽지 않고 인덱스만 읽어서 쿼리를 모두 처리할 수 있을 때 Extra 컬럼에 Using index가 표시된다.
  - InnoDB의 모든 테이블은 클러스터링 인덱스로 구성되어, 모든 세컨더리 인덱스는 데이터 레코드의 주소값으로 프라이머리 키 값을 가진다. 이러한 특성으로 PK와 세컨더리 인덱스를 사용하는 쿼리는 커버링 인덱스로 처리될 가능성이 높다. 즉 세컨더리 인덱스에는 데이터 레코드를 찾아가기 위한 주소로 사용하기 위해 PK를 저장해 두는 것이지만 추가 컬럼을 하나 더 가지는 효과를 얻을 수 있다.
  - 레코드 건수에 따라 차이는 있겠지만 쿼리를 커버링 인덱스로 처리할 수 있을 때와 없을 때는 수십배, 수백배 까지 차이가 날 수 있다. 하지만 무조건 커버링 인덱스로 처리하려고 인덱스를 추가하면 쓰기 작업이 매우 느려질 수 있으니 알고 있어야 한다.
- **Using index for group-by**
  - MySQL 서버는 Group by 처리를 위해 그루핑 기준 컬럼을 이용해 정렬을 수행하고, 정렬된 결과를 그루핑하는 형태의 고부하 작업을 한다.
  - 하지만 group by가 인덱스를 이용하면 정렬된 인덱스 컬럼을 순서대로 읽으면서 그루핑 작업만 수행하는데, 이 때 표시된다.
- **Using join buffer**
  - 일반적으로 조인되는 컬럼은 인덱스를 생성한다. 실제로 조인에 필요한 인덱스는, 양쪽 모두가 필요한게 아니라 조인에서 뒤에 읽는 테이블의 칼럼에만 필요하다. 옵티마이저도 두 테이블에 있는 컬럼에서 인덱스를 조사하고 인덱스가 없는 테이블이 있으면 그 테이블을 먼저 읽어서 조인을 실행한다. 드리븐 테이블이 검색 위주로 사용되기 때문에 인덱스가 없다면 성능에 영향이 크기 때문이다.
  - 드리븐 테이블에 검색을 위한 적절한 인덱스가 없다면 MySQL 서버는 블록 네스티드 루프 조인이나 해시 조인을 사용하며 이때 조인 버퍼를 사용하게 된다.
- **Using temporary**
  - 쿼리를 처리하는 동안 중간 결과를 담아두기 위해 임시 테이블을 사용한다. 임시 테이블은 메모리 or 디스크상에 생성될 수 있다. Extra 컬럼에 Using temporary 키워드가 뜨면 임시 테이블을 사용한 것인데 이때 임시 테이블이 메모리에 생성됐는지 디스크에 생성됐는지는 판단할 수 없다.
