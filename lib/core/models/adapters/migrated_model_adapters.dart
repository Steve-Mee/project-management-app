import 'package:hive/hive.dart';
import 'package:project_management_app/core/auth/auth_user.dart';
import 'package:project_management_app/core/auth/role_models.dart';
import 'package:project_management_app/core/models/ai_rate_limits_config.dart';
import 'package:project_management_app/core/models/ai_request_queue.dart';
import 'package:project_management_app/core/models/ai_usage_record.dart';
import 'package:project_management_app/core/models/dashboard_types.dart';
import 'package:project_management_app/core/models/requirements.dart';
import 'package:project_management_app/core/repository/models/dashboard_models.dart';
import 'package:project_management_app/models/chat_message_model.dart';
import 'package:project_management_app/models/comment_model.dart';
import 'package:project_management_app/models/project_filter.dart';
import 'package:project_management_app/models/project_invitation.dart';
import 'package:project_management_app/models/project_meta.dart';
import 'package:project_management_app/models/project_model.dart';
import 'package:project_management_app/models/project_plan.dart';
import 'package:project_management_app/models/project_requirements.dart';
import 'package:project_management_app/models/sub_task_model.dart';
import 'package:project_management_app/models/task_model.dart';

import 'project_filter_conditions_adapter.dart';
import 'safe_json_hive_adapter.dart';

class SafeChatMessageAdapter extends SafeJsonHiveAdapter<ChatMessage> {
  SafeChatMessageAdapter()
      : super(
          typeId: 100,
          fromJson: ChatMessage.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeCommentModelAdapter extends SafeJsonHiveAdapter<CommentModel> {
  SafeCommentModelAdapter()
      : super(
          typeId: 101,
          fromJson: CommentModel.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeProjectFilterAdapter extends SafeJsonHiveAdapter<ProjectFilter> {
  SafeProjectFilterAdapter()
      : super(
          typeId: 102,
          fromJson: ProjectFilter.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeProjectInvitationAdapter
    extends SafeJsonHiveAdapter<ProjectInvitation> {
  SafeProjectInvitationAdapter()
      : super(
          typeId: 103,
          fromJson: ProjectInvitation.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeProjectMetaAdapter extends SafeJsonHiveAdapter<ProjectMeta> {
  SafeProjectMetaAdapter()
      : super(
          typeId: 104,
          fromJson: ProjectMeta.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafePlanTaskAdapter extends SafeJsonHiveAdapter<PlanTask> {
  SafePlanTaskAdapter()
      : super(
          typeId: 105,
          fromJson: PlanTask.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafePlanChapterAdapter extends SafeJsonHiveAdapter<PlanChapter> {
  SafePlanChapterAdapter()
      : super(
          typeId: 106,
          fromJson: PlanChapter.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeProjectPlanAdapter extends SafeJsonHiveAdapter<ProjectPlan> {
  SafeProjectPlanAdapter()
      : super(
          typeId: 107,
          fromJson: ProjectPlan.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeProjectModelAdapter extends SafeJsonHiveAdapter<ProjectModel> {
  SafeProjectModelAdapter()
      : super(
          typeId: 108,
          fromJson: ProjectModel.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeProjectRequirementsAdapter
    extends SafeJsonHiveAdapter<ProjectRequirements> {
  SafeProjectRequirementsAdapter()
      : super(
          typeId: 109,
          fromJson: ProjectRequirements.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeSubTaskAdapter extends SafeJsonHiveAdapter<SubTask> {
  SafeSubTaskAdapter()
      : super(
          typeId: 110,
          fromJson: SubTask.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeTaskAdapter extends SafeJsonHiveAdapter<Task> {
  SafeTaskAdapter()
      : super(
          typeId: 111,
          fromJson: Task.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeAiUsageRecordAdapter extends SafeJsonHiveAdapter<AiUsageRecord> {
  SafeAiUsageRecordAdapter()
      : super(
          typeId: 112,
          fromJson: AiUsageRecord.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeRequirementAdapter extends SafeJsonHiveAdapter<Requirement> {
  SafeRequirementAdapter()
      : super(
          typeId: 113,
          fromJson: Requirement.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeDashboardItemAdapter extends SafeJsonHiveAdapter<DashboardItem> {
  SafeDashboardItemAdapter()
      : super(
          typeId: 114,
          fromJson: DashboardItem.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeDashboardTemplateAdapter
    extends SafeJsonHiveAdapter<DashboardTemplate> {
  SafeDashboardTemplateAdapter()
      : super(
          typeId: 115,
          fromJson: DashboardTemplate.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeSharedDashboardAdapter extends SafeJsonHiveAdapter<SharedDashboard> {
  SafeSharedDashboardAdapter()
      : super(
          typeId: 116,
          fromJson: SharedDashboard.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeAiRateLimitsConfigAdapter
    extends SafeJsonHiveAdapter<AiRateLimitsConfig> {
  SafeAiRateLimitsConfigAdapter()
      : super(
          typeId: 117,
          fromJson: AiRateLimitsConfig.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeAiRequestAdapter extends SafeJsonHiveAdapter<AiRequest> {
  SafeAiRequestAdapter()
      : super(
          typeId: 118,
          fromJson: AiRequest.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeQueueMetricsAdapter extends SafeJsonHiveAdapter<QueueMetrics> {
  SafeQueueMetricsAdapter()
      : super(
          typeId: 119,
          fromJson: QueueMetrics.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeRoleDefinitionAdapter extends SafeJsonHiveAdapter<RoleDefinition> {
  SafeRoleDefinitionAdapter()
      : super(
          typeId: 120,
          fromJson: RoleDefinition.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeGroupDefinitionAdapter extends SafeJsonHiveAdapter<GroupDefinition> {
  SafeGroupDefinitionAdapter()
      : super(
          typeId: 121,
          fromJson: GroupDefinition.fromJson,
          toJson: (value) => value.toJson(),
        );
}

class SafeAppUserAdapter extends SafeJsonHiveAdapter<AppUser> {
  SafeAppUserAdapter()
      : super(
          typeId: 122,
          fromJson: AppUser.fromJson,
          toJson: (value) => value.toJson(),
        );
}

void registerSafeMigratedModelAdapters() {
  final adapters = <TypeAdapter<dynamic>>[
    SafeChatMessageAdapter(),
    SafeCommentModelAdapter(),
    SafeProjectFilterAdapter(),
    SafeProjectInvitationAdapter(),
    SafeProjectMetaAdapter(),
    SafePlanTaskAdapter(),
    SafePlanChapterAdapter(),
    SafeProjectPlanAdapter(),
    SafeProjectModelAdapter(),
    SafeProjectRequirementsAdapter(),
    SafeSubTaskAdapter(),
    SafeTaskAdapter(),
    SafeAiUsageRecordAdapter(),
    SafeRequirementAdapter(),
    SafeDashboardItemAdapter(),
    SafeDashboardTemplateAdapter(),
    SafeSharedDashboardAdapter(),
    SafeAiRateLimitsConfigAdapter(),
    SafeAiRequestAdapter(),
    SafeQueueMetricsAdapter(),
    SafeRoleDefinitionAdapter(),
    SafeGroupDefinitionAdapter(),
    SafeAppUserAdapter(),
    ProjectFilterConditionsAdapter(),
  ];

  for (final adapter in adapters) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }
}
