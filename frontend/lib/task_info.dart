class TaskInfo {

  int state; //TODO possible values check
  String description;
  DateTime deadline;
  int id = -1;

  TaskInfo(this.state){
    description = "";
    deadline = null;
  }

  TaskInfo.full(this.state, this.description, this.deadline, this.id);

}