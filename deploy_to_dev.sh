echo "---------- run deploy_to_dev --------------"

echo "SECOND_MODULE is ${SECOND_MODULE}"
echo "THIRD_MODULE is ${THIRD_MODULE}"

cd helm/${APP_PROJECT_NAME}/${APP_CHART_NAME}
EXPECT_CHART=`echo ${GITHUB_REPOSITORY} | awk -F "/" '{print $2}'`
TARGET_CHART=`yq r Chart.yaml name`
echo "verify the EXPECT_CHART:$EXPECT_CHART and TARGET_CHART:$TARGET_CHART"
if [ "$EXPECT_CHART" != "$TARGET_CHART" ];then
echo "TARGET_CHART $TARGET_CHART not same as EXPECT_CHART $EXPECT_CHART, please check"
exit 1
fi


if [ "$SECOND_MODULE" != "false" ];then
echo ${SECOND_MODULE_FOR_COMMON} | awk  '{print $1}'
COMMON_FOR_SECOND_MODULE=`echo ${SECOND_MODULE_FOR_COMMON} | awk  '{print $1}'`
TAG_FOR_SECOND_MODULE=`yq r --printMode pv values.yml ${COMMON_FOR_SECOND_MODULE}.image.tag`
fi
if [ "$THIRD_MODULE" != "false" ];then
echo ${THIRD_MODULE_FOR_COMMON} | awk  '{print $1}'
COMMON_FOR_THIRD_MODULE=`echo ${THIRD_MODULE_FOR_COMMON} | awk  '{print $1}'`
TAG_FOR_THIRD_MODULE=`yq r --printMode pv values.yml ${COMMON_FOR_THIRD_MODULE}.image.tag`
fi

echo "list current common*.image.tag"
yq r --printMode pv values.yaml "common*.image.tag"
echo "latest GITLAB_IMAGE_TAG is ${GITHUB_SHA:0:8}"            
yq w -i values.yaml "common*.image.tag" ${GITHUB_SHA:0:8}
yq r --printMode pv values.yaml "common*.image.tag"

if [ "$SECOND_MODULE" != "false" ];then
for w in `echo ${SECOND_MODULE_FOR_COMMON}` do yq w -i values.yaml ${w}.image.tag ${TAG_FOR_SECOND_MODULE}; done
fi
if [ "$THIRD_MODULE" != "false" ];then
for w in `echo ${THIRD_MODULE_FOR_COMMON}` do yq w -i values.yaml ${w}.image.tag ${TAG_FOR_THIRD_MODULE}; done
fi

yq r --printMode pv values.yaml "common*.image.tag"

echo "push the latest SHA: ${GITHUB_SHA:0:8} to manifest repo"
git config user.name ${GITHUB_ACTOR}
git config user.email ${GITHUB_ACTOR}@github.com
git diff
git add ./
git commit -m "${GITHUB_REPOSITORY}_${GITHUB_JOB}_${GITHUB_SHA:0:8}_details:${CI_COMMIT_MESSAGE}"
git push
echo -e "======================= \n\n you can check your application status with 'user/passwd:readonly/Te****g' at \n\n \033[31m https://g-argocd.fluxble.com/applications/${APP_PROJECT_NAME}-${APP_CHART_NAME}\033[0m \n\n======================="