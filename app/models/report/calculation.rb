class Report::Calculation < ActiveRecord::Base
  belongs_to :report, :class_name => "Report::Report", :foreign_key => "report_report_id"
  belongs_to :question1, :class_name => "Question"
  belongs_to :question2, :class_name => "Question"

  # convenience getters and setters
  def arg1; arg(1); end
  def arg2; arg(2); end
  def arg1=(arg); set_arg(1, arg); end
  def arg2=(arg); set_arg(2, arg); end
  def attrib1; @attrib1 ||= attrib(1); end
  def attrib2; @attrib1 ||= attrib(2); end
  def attrib1=(attrib); set_attrib(1, attrib); end
  def attrib2=(attrib); set_attrib(2, attrib); end
  def questions; [question1, question2].compact; end
  private
    def arg(num)
      if q = self.send("question#{num}")
        return q
      else
        return self.send("attrib#{num}")
      end
    end
  
    def set_arg(num, arg)
      if arg.is_a?(Question)
        self.send("question#{num}=", arg)
      else
        self.send("attrib#{num}=", arg)
      end
    end
  
    def attrib(num)
      return Report::Attrib.get(self.send("attrib#{num}_name"))
    end
  
    def set_attrib(num, attrib)
      self.send("attrib#{num}_name=", attrib.name)
    end
end
