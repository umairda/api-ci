CXX := g++
CXXFLAGS := -std=c++17 -Wall -Wextra -Werror -I./src
LDFLAGS :=
TEST_LIBS := -lgtest -lgtest_main -lpthread
COVERAGE_FLAGS := -fprofile-arcs -ftest-coverage

ifeq ($(shell command -v pkg-config >/dev/null 2>&1 && echo yes),yes)
ifneq ($(shell pkg-config --exists gtest && echo yes),)
GTEST_CFLAGS := $(shell pkg-config --cflags gtest)
GTEST_LIBS := $(shell pkg-config --libs gtest)
CXXFLAGS += $(GTEST_CFLAGS)
TEST_LIBS := $(GTEST_LIBS) -lpthread
endif
endif

ifeq ($(shell command -v brew >/dev/null 2>&1 && echo yes),yes)
ifneq ($(shell test -d "$$(brew --prefix googletest 2>/dev/null)/include/gtest" && echo yes),)
GTEST_PREFIX := $(shell brew --prefix googletest)
CXXFLAGS += -I$(GTEST_PREFIX)/include
TEST_LIBS := -L$(GTEST_PREFIX)/lib -lgtest -lgtest_main -lpthread
endif
endif

BUILD_DIR := build
APP := $(BUILD_DIR)/health_api
TEST_BIN := $(BUILD_DIR)/health_api_tests
IMAGE_NAME ?= health-api
IMAGE_TAG ?= local
CONTAINER_NAME ?= health-api-local
PORT ?= 8080

SRC := src/main.cpp src/health_api.cpp
LIB_SRC := src/health_api.cpp
TEST_SRC := tests/test_health_api.cpp

.PHONY: all clean run test coverage docker-build docker-run docker-test docker-stop
.PHONY: local-ci-up local-ci-down local-ci-password

all: $(APP)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(APP): $(BUILD_DIR) $(SRC)
	$(CXX) $(CXXFLAGS) $(SRC) -o $@ $(LDFLAGS)

run: $(APP)
	./$(APP)

test: $(TEST_BIN)
	./$(TEST_BIN)

$(TEST_BIN): $(BUILD_DIR) $(LIB_SRC) $(TEST_SRC)
	$(CXX) $(CXXFLAGS) $(LIB_SRC) $(TEST_SRC) -o $@ $(TEST_LIBS)

coverage: clean
	mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(COVERAGE_FLAGS) $(LIB_SRC) $(TEST_SRC) -o $(TEST_BIN) $(TEST_LIBS)
	./$(TEST_BIN)
	gcov -o $(BUILD_DIR) src/health_api.cpp

docker-build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

docker-run:
	docker run --rm -d -p $(PORT):8080 --name $(CONTAINER_NAME) $(IMAGE_NAME):$(IMAGE_TAG)

docker-test:
	curl -i http://localhost:$(PORT)/health

docker-stop:
	-docker stop $(CONTAINER_NAME)

local-ci-up:
	./scripts/local_ci_up.sh

local-ci-down:
	./scripts/local_ci_down.sh

local-ci-password:
	docker exec local-jenkins cat /var/jenkins_home/secrets/initialAdminPassword

clean:
	rm -rf $(BUILD_DIR) *.gcda *.gcno *.gcov src/*.gcda src/*.gcno src/*.gcov tests/*.gcda tests/*.gcno tests/*.gcov
