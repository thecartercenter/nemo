class AddObserverIdToMainView < ActiveRecord::Migration
  def self.up
    # must drop the view first since it already exists and there is no way to modify a view
    drop_view :_answers rescue nil
    create_view(:_answers, "
      select 
        r.id AS response_id,
        r.observed_at AS observation_time,
        r.reviewed AS is_reviewed,
        f.name AS form_name,
        ft.name AS form_type,
        q.code AS question_code,
        qtr.str AS question_name,
        qt.name AS question_type,
        u.id AS user_id,
        concat(u.first_name, ' ', u.last_name) AS observer_name,
        adr.full_name AS place_full_name,
        adr.long_name AS address_landmark,
        loc.long_name AS locality,
        sta.long_name AS state,
        cry.long_name AS country,
        adr.latitude AS latitude,
        adr.longitude AS longitude,
        concat(adr.latitude,',',adr.longitude) AS latitude_longitude,
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
          left join places adr on r.place_id = adr.id
            left join places loc on adr.container_id = loc.id
              left join places sta on loc.container_id = sta.id
                left join places cry on sta.container_id = cry.id
        join questionings qing on a.questioning_id = qing.id
          join questions q on qing.question_id = q.id
            join question_types qt on q.question_type_id = qt.id 
            left join option_sets os on q.option_set_id = os.id
              join translations qtr on (qtr.obj_id = q.id and qtr.fld = 'name' and qtr.class_name = 'Question' 
                and qtr.language_id = (select id from languages where code = 'eng'))
    ") do |t|
      t.column :response_id
      t.column :observation_time
      t.column :is_reviewed
      t.column :form_name
      t.column :form_type
      t.column :question_code
      t.column :question_name
      t.column :question_type
      t.column :user_id
      t.column :observer_name
      t.column :place_full_name
      t.column :address_landmark
      t.column :locality
      t.column :state
      t.column :country
      t.column :latitude
      t.column :longitude
      t.column :latitude_longitude
      t.column :answer_id
      t.column :answer_value
      t.column :choice_name
      t.column :choice_value
      t.column :option_set
    end
  end

  def self.down
    drop_view :_answers
  end
end