echo "deploy_to_dev"

cd helm/${APP_PROJECT_NAME}/${APP_CHART_NAME}
EXPECT_CHART=`echo ${GITHUB_REPOSITORY} | awk -F "/" '{print $2}'`
TARGET_CHART=`yq r Chart.yaml name`
echo "verify the EXPECT_CHART:$EXPECT_CHART and TARGET_CHART:$TARGET_CHART"
if [ "$EXPECT_CHART" != "$TARGET_CHART" ];then
echo "TARGET_CHART $TARGET_CHART not same as EXPECT_CHART $EXPECT_CHART, please check"
exit 1
fi

echo "list current common*.image.repository"
yq r --printMode pv values.yaml "common*.image.repository"
echo "latest GITLAB_IMAGE_NAME is ${GITLAB_REGISTRY}/${GITHUB_REPOSITORY}"
yq w -i values.yaml "common*.image.repository" ${GITLAB_REGISTRY}/${GITHUB_REPOSITORY}
yq r --printMode pv values.yaml "common*.image.repository"
            
echo "list current common*.image.tag"
yq r --printMode pv values.yaml "common*.image.tag"
echo "latest GITLAB_IMAGE_TAG is sha-${GITHUB_SHA:0:7}"            
yq w -i values.yaml "common*.image.tag" sha-${GITHUB_SHA:0:7}
yq r --printMode pv values.yaml "common*.image.tag"