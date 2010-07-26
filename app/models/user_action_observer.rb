class UserActionObserver < ActiveRecord::Observer
  observe User, Page, Layout, Snippet, PageVersion, Condition, ConditionVersion, Abstract, 
          ResearchTopic, ResearchTopicVersion, Treatment, TreatmentVersion, Review, ReviewVersion,
          QuestionTopic, QuestionTopicVersion, Question, QuestionVersion, Doctor, DoctorVersion,
          Faq, FaqVersion, EventTopic, EventTopicVersion, Event, EventVersion, Term, TermVersion
  
  cattr_accessor :current_user
  
  def before_create(model)
    model.created_by = @@current_user
  end
  
  def before_update(model)
    model.updated_by = @@current_user
  end
end