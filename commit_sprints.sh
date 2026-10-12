#!/usr/bin/env bash
# ==============================================================================
# SCRIPT TỰ ĐỘNG KHỞI TẠO VÀ COMMIT LỊCH SỬ GIT THEO TIẾN ĐỘ SPRINT
# Dự án: All-in-One Field Inventory & Edge AI Suite
# Tác giả: Senior Tech Lead & Git Specialist
# ==============================================================================

set -e

# Mã màu giao diện Terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}   KHỞI TẠO VÀ COMMIT LỊCH SỬ GIT THEO TIẾN ĐỘ 4 SPRINT (TRELLO)      ${NC}"
echo -e "${CYAN}   Dự án: All-in-One Field Inventory & Edge AI Suite                  ${NC}"
echo -e "${CYAN}======================================================================${NC}"

# 0. Xử lý thư mục .git nếu đã tồn tại
if [ -d ".git" ]; then
    if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
        echo -e "${YELLOW}[!] Phát hiện thư mục .git hiện tại. Đang xóa để khởi tạo lại từ đầu (--force)...${NC}"
        rm -rf .git
    else
        echo -e "${YELLOW}[!] Thư mục .git đã tồn tại trong repository.${NC}"
        echo -e "Bạn có muốn xóa để tạo mới lại toàn bộ lịch sử commit theo Sprint không? (y/N): "
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            rm -rf .git
            echo -e "${GREEN}[✓] Đã dọn dẹp .git cũ thành công.${NC}"
        else
            echo -e "${RED}[x] Hủy thực thi kịch bản.${NC}"
            exit 1
        fi
    fi
fi

# 1. Khởi tạo Git Repo & Nhánh main
echo -e "\n${BLUE}==> [BƯỚC 1] Khởi tạo Git Repository (Nhánh main)...${NC}"
git init -b main

# Cấu hình danh tính Git nội bộ nếu chưa có
git config user.name "Senior Lead Developer"
git config user.email "lead.dev@fieldinventory.ai"

# Commit nền tảng ban đầu
git add .gitignore README.md
git commit -m "chore: initial commit with gitignore and project readme"
echo -e "${GREEN}[✓] Hoàn thành Initial Commit trên nhánh main.${NC}"

# ==============================================================================
# SPRINT 1: Computer Vision & AI Pipeline (Tuần 1–3)
# ==============================================================================
echo -e "\n${BLUE}==> [BƯỚC 2] Bắt đầu SPRINT 1: Computer Vision & AI Pipeline...${NC}"
git checkout -b sprint-1

# Card 1: Thu thập và chuẩn bị Dataset ảnh hỏng hóc/thiết bị
echo -e "${CYAN}    -> Commit Card 1: Dataset & Labels...${NC}"
git add assets/models/labels.txt
git commit -m "feat(cv): Card 1 - Thu thap va chuan bi Dataset anh thiet bi (labels.txt)"

# Card 2: Huấn luyện mô hình Object Detection (YOLOv8/MobileNet)
echo -e "${CYAN}    -> Commit Card 2: AI Pipeline & Config...${NC}"
git add lib/core/ai_pipeline/ai_config.dart
git commit -m "feat(cv): Card 2 - Huan luyen mo hinh Object Detection va thiet lap thong so AI"

# Card 3: Lượng tử hóa và xuất mô hình (Quantization & Export)
echo -e "${CYAN}    -> Commit Card 3: Export TFLite Model...${NC}"
git add assets/models/object_detection.tflite
git commit -m "feat(cv): Card 3 - Luong tu hoa va xuat mo hinh TFLite on-device"

# Merge Sprint 1 về main
echo -e "${CYAN}    -> Merge sprint-1 về main (--no-ff) & Đánh Tag v0.1-sprint1...${NC}"
git checkout main
git merge --no-ff sprint-1 -m "merge: Sprint 1 - Computer Vision & AI Pipeline"
git tag -a v0.1-sprint1 -m "Release v0.1: Hoàn thành Sprint 1 (CV & AI Pipeline)"
echo -e "${GREEN}[✓] Đã hợp nhất Sprint 1 vào main thành công! Tag: v0.1-sprint1${NC}"

# ==============================================================================
# SPRINT 2: Flutter App Core & Edge AI (Tuần 4–5)
# ==============================================================================
echo -e "\n${BLUE}==> [BƯỚC 3] Bắt đầu SPRINT 2: Flutter App Core & Edge AI...${NC}"
git checkout -b sprint-2

# Card 4: Khởi tạo project Flutter & Clean Architecture
echo -e "${CYAN}    -> Commit Card 4: Flutter Boilerplate & Clean Architecture Skeleton...${NC}"
git add pubspec.yaml pubspec.lock analysis_options.yaml .metadata \
        android/ ios/ macos/ web/ windows/ .vscode/ \
        lib/main.dart lib/core/router/ \
        $(find lib -name ".gitkeep") \
        test/widget_test.dart
git commit -m "feat(core): Card 4 - Khoi tao project Flutter va khung Clean Architecture"

# Card 5: Tích hợp luồng Camera & Mobile Scanner
echo -e "${CYAN}    -> Commit Card 5: Mobile Scanner & Camera Stream...${NC}"
git add lib/features/edge_vision/domain/entities/scan_result.dart \
        lib/features/edge_vision/domain/repositories/scanner_repository.dart \
        lib/features/edge_vision/domain/usecases/process_scan_result_usecase.dart \
        lib/features/edge_vision/data/repositories/scanner_repository_impl.dart \
        lib/features/edge_vision/presentation/widgets/scanner_overlay.dart \
        lib/features/edge_vision/presentation/screens/scanner_screen.dart \
        test/features/edge_vision/process_scan_result_usecase_test.dart
git commit -m "feat(scanner): Card 5 - Tich hop luong Camera va Mobile Scanner ML Kit"

# Card 6: Nhúng TFLite & Chạy Inference On-Device
echo -e "${CYAN}    -> Commit Card 6: On-Device TFLite Inference & CPU Drop-frame...${NC}"
git add lib/features/edge_vision/domain/repositories/vision_ai_repository.dart \
        lib/features/edge_vision/data/repositories/tflite_vision_repository_impl.dart \
        lib/features/edge_vision/data/repositories/tflite_vision_repository_impl.g.dart \
        lib/features/edge_vision/presentation/controllers/scanner_controller.dart \
        lib/features/edge_vision/presentation/controllers/scanner_controller.g.dart \
        test/features/edge_vision/vision_ai_repository_test.dart
git commit -m "feat(ai): Card 6 - Nhung TFLite va chay suy luan On-Device realtime"

# Merge Sprint 2 về main
echo -e "${CYAN}    -> Merge sprint-2 về main (--no-ff) & Đánh Tag v0.2-sprint2...${NC}"
git checkout main
git merge --no-ff sprint-2 -m "merge: Sprint 2 - Flutter App Core & Edge AI"
git tag -a v0.2-sprint2 -m "Release v0.2: Hoàn thành Sprint 2 (Flutter Core & Edge AI)"
echo -e "${GREEN}[✓] Đã hợp nhất Sprint 2 vào main thành công! Tag: v0.2-sprint2${NC}"

# ==============================================================================
# SPRINT 3: Offline-First Database & Custom Canvas (Tuần 6–7)
# ==============================================================================
echo -e "\n${BLUE}==> [BƯỚC 4] Bắt đầu SPRINT 3: Offline-First Database & Custom Canvas...${NC}"
git checkout -b sprint-3

# Card 7: Thiết lập Local Database với Isar
echo -e "${CYAN}    -> Commit Card 7: Isar Database & Audit Collections...${NC}"
git add lib/core/database/local_db_init.dart \
        lib/core/database/local_db_init.g.dart \
        lib/features/offline_audit/data/models/audit_record_model.dart \
        lib/features/offline_audit/data/models/audit_record_model.g.dart \
        lib/features/offline_audit/domain/repositories/audit_repository.dart \
        lib/features/offline_audit/data/repositories/isar_audit_repository_impl.dart \
        lib/features/offline_audit/data/repositories/isar_audit_repository_impl.g.dart
git commit -m "feat(db): Card 7 - Thiet lap Local Database voi Isar Plus offline-first"

# Card 8: Màn hình Biểu mẫu kiểm kê động (Dynamic Form)
echo -e "${CYAN}    -> Commit Card 8: Dynamic Audit Form Screen...${NC}"
git add lib/features/offline_audit/presentation/controllers/audit_form_controller.dart \
        lib/features/offline_audit/presentation/controllers/audit_form_controller.g.dart \
        lib/features/offline_audit/presentation/screens/audit_form_screen.dart \
        test/features/offline_audit/audit_form_controller_test.dart \
        test/features/offline_audit/audit_form_screen_test.dart
git commit -m "feat(audit): Card 8 - Man hinh bieu mau kiem ke dong va quan ly trang thai"

# Card 9: Tích hợp Custom Canvas (Chữ ký & Ghi chú ảnh)
echo -e "${CYAN}    -> Commit Card 9: Custom Signature Canvas & PNG Byte Pipeline...${NC}"
git add lib/features/canvas_signature/presentation/screens/signature_screen.dart \
        test/features/canvas_signature/signature_screen_test.dart
git commit -m "feat(canvas): Card 9 - Tich hop Custom Canvas chu ky so va xuat PNG bytes"

# Merge Sprint 3 về main
echo -e "${CYAN}    -> Merge sprint-3 về main (--no-ff) & Đánh Tag v0.3-sprint3...${NC}"
git checkout main
git merge --no-ff sprint-3 -m "merge: Sprint 3 - Offline-First Database & Custom Canvas"
git tag -a v0.3-sprint3 -m "Release v0.3: Hoàn thành Sprint 3 (Isar Local DB & Signature Canvas)"
echo -e "${GREEN}[✓] Đã hợp nhất Sprint 3 vào main thành công! Tag: v0.3-sprint3${NC}"

# ==============================================================================
# SPRINT 4: Cloud Sync & Export (Tuần 8–9)
# ==============================================================================
echo -e "\n${BLUE}==> [BƯỚC 5] Bắt đầu SPRINT 4: Cloud Sync & Export...${NC}"
git checkout -b sprint-4

# Card 10: Thiết lập Backend & Cloud Sync (Supabase)
echo -e "${CYAN}    -> Commit Card 10: Supabase BaaS Core & Cloud Sync Contract...${NC}"
git add lib/core/network/supabase_config.dart \
        lib/core/network/supabase_provider.dart \
        lib/core/network/supabase_provider.g.dart \
        lib/features/offline_audit/domain/repositories/sync_repository.dart \
        lib/features/offline_audit/data/models/cloud_audit_record_model.dart \
        test/features/offline_audit/cloud_audit_record_model_test.dart
git commit -m "feat(cloud): Card 10 - Thiet lap Backend Supabase Core va Cloud Sync contract"

# Card 11: Chức năng xuất Báo cáo PDF
echo -e "${CYAN}    -> Commit Card 11: Multi-page PDF Report Engine...${NC}"
git add lib/core/utils/pdf_report_generator.dart \
        test/core/utils/pdf_report_generator_test.dart
git commit -m "feat(report): Card 11 - Chuc nang xuat bao cao kiem ke PDF da trang chuan A4"

# Card 12: Tối ưu UI cho phiên bản Desktop
echo -e "${CYAN}    -> Commit Card 12: Responsive Layout (800px) & Desktop Dashboard...${NC}"
git add lib/core/utils/responsive_layout.dart \
        lib/features/report_dashboard/presentation/screens/dashboard_screen.dart \
        test/core/utils/responsive_layout_test.dart \
        test/features/report_dashboard/dashboard_screen_test.dart
git commit -m "feat(ui): Card 12 - Toi uu UI Responsive cho phien ban Desktop va Tablet"

# Merge Sprint 4 về main
echo -e "${CYAN}    -> Merge sprint-4 về main (--no-ff) & Đánh Tag v0.4-sprint4...${NC}"
git checkout main
git merge --no-ff sprint-4 -m "merge: Sprint 4 - Cloud Sync & Export"
git tag -a v0.4-sprint4 -m "Release v0.4: Hoàn thành Sprint 4 (Cloud Sync, PDF & Desktop UI)"
echo -e "${GREEN}[✓] Đã hợp nhất Sprint 4 vào main thành công! Tag: v0.4-sprint4${NC}"

# ==============================================================================
# SPRINT 5: Tài liệu Kiểm toán, Luận chứng & Đóng gói Nghiệm thu
# ==============================================================================
echo -e "\n${BLUE}==> [BƯỚC 6] Đóng gói Hồ sơ Nghiệm thu & Tài liệu Kỹ thuật...${NC}"
git add TECHNICAL_JUSTIFICATION.md \
        PROJECT_AUDIT_REPORT.md \
        git_sprint_commit_plan.md \
        commit_sprints.sh
git commit -m "docs(audit): Hoan thien bao cao kiem toan kien truc va ke hoach Git commit Sprint"
git tag -a v1.0.0-final -m "Release v1.0.0: Sẵn sàng bảo vệ đồ án tốt nghiệp Sprint 5"
echo -e "${GREEN}[✓] Đã commit hoàn tất tài liệu nghiệm thu! Tag: v1.0.0-final${NC}"

# ==============================================================================
# TỔNG KẾT CÂY LỊCH SỬ GIT
# ==============================================================================
echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${GREEN}   QUÁ TRÌNH TẠO LỊCH SỬ GIT THEO SPRINT ĐÃ HOÀN TẤT THÀNH CÔNG!     ${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo -e "\n${BLUE}Cây lịch sử commit Git (Graph Visualization):${NC}\n"
git log --graph --oneline --all --decorate -n 25

echo -e "\n${GREEN}[✓] Danh sách Tags phiên bản đã tạo:${NC}"
git tag -n1
