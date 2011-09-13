class FixPlacesInMainView < ActiveRecord::Migration
  def self.up
    # add a type code and container index to make this fast
    
    execute("DROP VIEW IF EXISTS _answers")
    execute("
    CREATE VIEW _answers AS 
      select 
        r.id AS response_id,
        r.observed_at AS observation_time,
        r.reviewed AS is_reviewed,
        f.name AS form_name,
        ft.name AS form_type,
        q.code AS question_code,
        qtr.str AS question_name,
        qt.name AS question_type,
        concat(u.first_name, ' ', u.last_name) AS observer_name,
        plc.full_name AS place_full_name,
        pnt.long_name AS point,
        adr.long_name AS address,
        loc.long_name AS locality,
        sta.long_name AS state,
        cry.long_name AS country,
        plc.latitude AS latitude,
        plc.longitude AS longitude,
        concat(plc.latitude,',',plc.longitude) AS latitude_longitude,
        a.id AS answer_id,
        a.value AS answer_value,
        IFNULL(aotr.str, cotr.str) AS choice_name,
        IFNULL(ao.value, co.value) AS choice_value,
        os.name AS option_set
      from answers a
        left join options ao on a.option_id = ao.id
          left join translations aotr on (aotr.obj_id = ao.id and aotr.fld = 'name' and aotr.class_name = 'Option' 
            and aotr.language_id = (select id from languages where code = 'eng'))
        left join choices c on c.answer_id = a.id
          left join options co on c.option_id = co.id
            left join translations cotr on (cotr.obj_id = co.id and cotr.fld = 'name' and cotr.class_name = 'Option' 
              and cotr.language_id = (select id from languages where code = 'eng'))
        join responses r on a.response_id = r.id
          join users u on r.user_id = u.id
          join forms f on r.form_id = f.id 
            join form_types ft on f.form_type_id = ft.id 
          left join places plc on r.place_id = plc.id
          left join places pnt on (plc.point_id = pnt.id)
          left join places adr on (plc.address_id = adr.id)
          left join places loc on (plc.locality_id = loc.id)
          left join places sta on (plc.state_id = sta.id)
          left join places cry on (plc.country_id = cry.id)
        join questionings qing on a.questioning_id = qing.id
          join questions q on qing.question_id = q.id
            join question_types qt on q.question_type_id = qt.id 
            left join option_sets os on q.option_set_id = os.id
              join translations qtr on (qtr.obj_id = q.id and qtr.fld = 'name' and qtr.class_name = 'Question' 
                and qtr.language_id = (select id from languages where code = 'eng'))
    ")
  end

  def self.down
  end
end
